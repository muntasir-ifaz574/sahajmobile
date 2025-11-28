import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'image_compression_service.dart';

class NidOcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from NID card image
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Parse Bangladesh NID card information from extracted text
  static Future<BangladeshNidInfo> parseNidInfo(String extractedText) async {
    try {
      final lines = extractedText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // Section-based parsing using labels
      Map<String, String> parsedFields = {};
      String? currentSection;
      List<String> valueBuffer = [];
      final labelToField = <String, String>{
        'NID No': 'nidNumber',
        'NID No.': 'nidNumber',
        'NID NO': 'nidNumber',
        'ID No': 'nidNumber',
        'ID NO': 'nidNumber',
        'Name': 'fullName',
        'নাম': 'fullName',
        'Date of Birth': 'dateOfBirth',
        'Birth Date': 'dateOfBirth',
        'DOB': 'dateOfBirth',
        'জন্ম তারিখ': 'dateOfBirth',
        'Sex': 'gender',
        'Gender': 'gender',
        'Address': 'address',
        'Present Address': 'address',
        'Permanent Address': 'address',
        'ঠিকানা': 'address',
        'Guarantor Name': 'guarantorName',
        'Guarantor\'s Name': 'guarantorName',
        'গ্যারান্টর নাম': 'guarantorName',
        'গ্যারান্টরের নাম': 'guarantorName',
        'Guarantor NID': 'guarantorNidNumber',
        'গ্যারান্টর NID': 'guarantorNidNumber',
        'Guarantor Address': 'guarantorAddress',
        'গ্যারান্টর ঠিকানা': 'guarantorAddress',
        'গ্যারান্টরের ঠিকানা': 'guarantorAddress',
        'Guarantor Phone': 'guarantorPhone',
        'Guarantor Mobile': 'guarantorPhone',
        'গ্যারান্টর ফোন': 'guarantorPhone',
        'গ্যারান্টর মোবাইল': 'guarantorPhone',
        'গ্যারান্টরের ফোন': 'guarantorPhone',
      };

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        String originalLine = line;
        bool foundLabel = false;

        for (String label in labelToField.keys) {
          if (line.contains(label)) {
            // Process previous buffer
            if (currentSection != null && valueBuffer.isNotEmpty) {
              String bufferedValue = valueBuffer.join(' ').trim();
              // Simple dedup for messy OCR
              bufferedValue = bufferedValue
                  .split(' ')
                  .where((word) => word.isNotEmpty)
                  .join(' ');
              // Clean leading/trailing colons and excessive spaces
              bufferedValue = bufferedValue
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              // Field-specific cleaning
              bufferedValue = _cleanFieldValue(currentSection, bufferedValue);
              parsedFields[currentSection] = bufferedValue;
              valueBuffer.clear();
            }
            currentSection = labelToField[label];
            foundLabel = true;

            // Extract remaining value from this line (pre-clean colon)
            String remaining = originalLine.replaceAll(label, '').trim();
            remaining = remaining
                .replaceAll(RegExp(r'^[:\s]+'), '')
                .trim(); // Remove leading colon/spaces
            if (remaining.isNotEmpty) {
              valueBuffer.add(remaining);
            }
            break;
          }
        }

        if (!foundLabel) {
          if (currentSection != null) {
            String trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              valueBuffer.add(trimmed);
            }
          }
        }
      }

      // Process last buffer
      if (currentSection != null && valueBuffer.isNotEmpty) {
        String bufferedValue = valueBuffer.join(' ').trim();
        bufferedValue = bufferedValue
            .split(' ')
            .where((word) => word.isNotEmpty)
            .join(' ');
        // Clean leading/trailing colons and excessive spaces
        bufferedValue = bufferedValue
            .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
            .trim();
        // Field-specific cleaning
        bufferedValue = _cleanFieldValue(currentSection, bufferedValue);
        parsedFields[currentSection] = bufferedValue;
      }

      // Initialize fields
      String nidNumber = parsedFields['nidNumber'] ?? '';
      String fullName = parsedFields['fullName'] ?? '';
      String dateOfBirth = parsedFields['dateOfBirth'] ?? '';
      String gender = parsedFields['gender'] ?? '';
      String address = parsedFields['address'] ?? '';
      String guarantorName = parsedFields['guarantorName'] ?? '';
      String guarantorNidNumber = parsedFields['guarantorNidNumber'] ?? '';
      String guarantorAddress = parsedFields['guarantorAddress'] ?? '';
      String guarantorPhone = parsedFields['guarantorPhone'] ?? '';

      // Fallback for NID Number
      if (nidNumber.isEmpty) {
        for (String line in lines) {
          String trimmed = line.trim();
          nidNumber = _extractNidNumber(trimmed);
          if (nidNumber.isNotEmpty) {
            break;
          }
        }
      }

      // Fallback for Full Name (prioritize English, fallback to Bengali)
      bool hasBengali = fullName.contains(RegExp(r'[\u0980-\u09FF]'));
      if (fullName.isEmpty || hasBengali) {
        for (int i = 0; i < lines.length; i++) {
          String line = lines[i];
          if (line.contains('নাম') || line.contains('Name')) {
            // Prioritize English name
            for (int j = i + 1; j < lines.length && j < i + 5; j++) {
              String nameLine = lines[j].trim();
              nameLine = nameLine
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              if (nameLine.isNotEmpty &&
                  !nameLine.contains('পিতা') &&
                  !nameLine.contains('মাতা') &&
                  !nameLine.contains('Date') &&
                  !nameLine.contains('NID') &&
                  !nameLine.contains('Name') &&
                  !RegExp(r'^\d+$').hasMatch(nameLine) &&
                  !nameLine.contains(RegExp(r'[\u0980-\u09FF]'))) {
                // Apply name-specific cleaning
                nameLine = _cleanName(nameLine);
                fullName = nameLine;
                break;
              }
            }
            // Fallback to Bengali if no English found
            if (fullName.isEmpty && i + 1 < lines.length) {
              String nextLine = lines[i + 1].trim();
              nextLine = nextLine
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              if (nextLine.contains(RegExp(r'[\u0980-\u09FF]'))) {
                fullName = nextLine;
              }
            }
            break;
          }
        }
      } else {
        // Clean even if already parsed
        fullName = _cleanName(fullName);
      }

      // Fallback for Date of Birth (enhanced with date validation)
      if (dateOfBirth.isEmpty) {
        List<String> potentialBirthDates = [];
        final Set<String> issueKeywords = {
          'issue',
          'issued',
          'valid',
          'expiry',
          'expire',
          'date of issue',
        };

        for (int i = 0; i < lines.length; i++) {
          String line = lines[i].trim();
          line = line.replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '').trim();
          if (_isPotentialDate(line)) {
            bool isIssueContext = false;
            // Check context +/- 2 lines
            for (
              int k = math.max(0, i - 2);
              k <= math.min(lines.length - 1, i + 2);
              k++
            ) {
              if (k != i) {
                String contextLine = lines[k].toLowerCase();
                if (issueKeywords.any(
                  (keyword) => contextLine.contains(keyword),
                )) {
                  isIssueContext = true;
                  break;
                }
              }
            }
            if (!isIssueContext) {
              DateTime? dt = _parseDate(line);
              if (dt != null) {
                // Use fixed current date for consistency (November 02, 2025)
                DateTime now = DateTime(2025, 11, 2);
                int ageDays = now.difference(dt).inDays;
                if (ageDays > 16 * 365 && ageDays < 120 * 365) {
                  potentialBirthDates.add(line);
                }
              }
            }
          }
        }
        if (potentialBirthDates.isNotEmpty) {
          dateOfBirth = potentialBirthDates.first;
        }
      }

      // Fallback for Gender (enhanced with relation indicators)
      if (gender.isEmpty) {
        for (String line in lines) {
          String lower = line.toLowerCase().trim();
          if (lower.contains('male')) {
            gender = 'Male';
            break;
          } else if (lower.contains('female')) {
            gender = 'Female';
            break;
          } else if (line.contains('পুরুষ')) {
            gender = 'Male';
            break;
          } else if (line.contains('মহিলা')) {
            gender = 'Female';
            break;
          } else if (lower.contains('son of')) {
            gender = 'Male';
            break;
          } else if (lower.contains('daughter of')) {
            gender = 'Female';
            break;
          }
        }
      }

      // Fallback for Address (multi-line collection)
      if (address.isEmpty) {
        for (int i = 0; i < lines.length; i++) {
          String line = lines[i];
          if (line.contains('ঠিকানা') || line.contains('Address')) {
            StringBuffer addr = StringBuffer();
            bool first = true;
            for (int j = i + 1; j < lines.length && j < i + 10; j++) {
              String next = lines[j].trim();
              next = next.replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '').trim();
              if (next.isEmpty) continue;
              // Stop if next looks like a label, pure number, or short
              if (labelToField.keys.any((l) => next.contains(l)) ||
                  RegExp(r'^\d+$').hasMatch(next) ||
                  next.length < 3) {
                break;
              }
              if (!first) addr.write(' ');
              addr.write(next);
              first = false;
            }
            address = addr.toString().trim();
            break;
          }
        }
      }

      // Fallback for Guarantor Information (as before, with cleaning)
      if (guarantorName.isEmpty) {
        for (int i = 0; i < lines.length; i++) {
          String line = lines[i];

          // Guarantor Name
          if (line.contains('গ্যারান্টর') ||
              line.contains('Guarantor') ||
              line.contains('গ্যারান্টর নাম') ||
              line.contains('Guarantor Name') ||
              line.contains('গ্যারান্টরের নাম') ||
              line.contains('গ্যারান্টর নামঃ')) {
            String nameText = line
                .replaceAll('গ্যারান্টর', '')
                .replaceAll('Guarantor', '')
                .replaceAll('গ্যারান্টর নাম', '')
                .replaceAll('Guarantor Name', '')
                .replaceAll('গ্যারান্টরের নাম', '')
                .replaceAll('গ্যারান্টর নামঃ', '')
                .replaceAll('নাম', '')
                .replaceAll('Name', '')
                .replaceAll('ঃ', '')
                .replaceAll(':', '')
                .trim();
            nameText = nameText
                .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                .trim();
            // Apply name-specific cleaning
            nameText = _cleanName(nameText);

            if (nameText.isNotEmpty && nameText != '.' && nameText.length > 2) {
              guarantorName = nameText;
            } else if (i + 1 < lines.length) {
              String nextLine = lines[i + 1].trim();
              nextLine = nextLine
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              // Apply cleaning
              nextLine = _cleanName(nextLine);
              if (nextLine.isNotEmpty &&
                  !nextLine.contains('NID') &&
                  !nextLine.contains('ঠিকানা') &&
                  !nextLine.contains('Address') &&
                  !nextLine.contains('ফোন') &&
                  !nextLine.contains('Phone') &&
                  !RegExp(r'^\d+$').hasMatch(nextLine) &&
                  nextLine.length > 2) {
                guarantorName = nextLine;
              }
            }
            break; // Only once
          }

          // Guarantor NID Number
          if (guarantorNidNumber.isEmpty &&
              (line.contains('গ্যারান্টর NID') ||
                  line.contains('Guarantor NID') ||
                  line.contains('গ্যারান্টর NID No') ||
                  line.contains('Guarantor NID No') ||
                  line.contains('গ্যারান্টর NID নং') ||
                  line.contains('গ্যারান্টর NIDঃ'))) {
            String nidText = line
                .replaceAll('গ্যারান্টর NID', '')
                .replaceAll('Guarantor NID', '')
                .replaceAll('গ্যারান্টর NID No', '')
                .replaceAll('Guarantor NID No', '')
                .replaceAll('গ্যারান্টর NID নং', '')
                .replaceAll('গ্যারান্টর NIDঃ', '')
                .replaceAll('NID No', '')
                .replaceAll('NID No.', '')
                .replaceAll('নং', '')
                .replaceAll('ঃ', '')
                .replaceAll(':', '')
                .trim();
            nidText = nidText.replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '').trim();
            guarantorNidNumber = _extractNidNumber(nidText);
          } else if (i + 1 < lines.length && guarantorNidNumber.isEmpty) {
            String nextLine = lines[i + 1].trim();
            nextLine = nextLine
                .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                .trim();
            guarantorNidNumber = _extractNidNumber(nextLine);
          }

          // Guarantor Address
          if (guarantorAddress.isEmpty &&
              (line.contains('গ্যারান্টর ঠিকানা') ||
                  line.contains('Guarantor Address') ||
                  line.contains('গ্যারান্টরের ঠিকানা') ||
                  line.contains('গ্যারান্টর ঠিকানাঃ'))) {
            String addressText = line
                .replaceAll('গ্যারান্টর ঠিকানা', '')
                .replaceAll('Guarantor Address', '')
                .replaceAll('গ্যারান্টরের ঠিকানা', '')
                .replaceAll('গ্যারান্টর ঠিকানাঃ', '')
                .replaceAll('ঠিকানা', '')
                .replaceAll('Address', '')
                .replaceAll('ঃ', '')
                .replaceAll(':', '')
                .trim();
            addressText = addressText
                .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                .trim();

            if (addressText.isNotEmpty && addressText.length > 5) {
              guarantorAddress = addressText;
            } else if (i + 1 < lines.length) {
              String nextLine = lines[i + 1].trim();
              nextLine = nextLine
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              if (nextLine.isNotEmpty &&
                  !nextLine.contains('ফোন') &&
                  !nextLine.contains('Phone') &&
                  !RegExp(r'^\d+$').hasMatch(nextLine) &&
                  nextLine.length > 5) {
                guarantorAddress = nextLine;
              }
            }
          }

          // Guarantor Phone
          if (guarantorPhone.isEmpty &&
              (line.contains('গ্যারান্টর ফোন') ||
                  line.contains('Guarantor Phone') ||
                  line.contains('গ্যারান্টর মোবাইল') ||
                  line.contains('Guarantor Mobile') ||
                  line.contains('গ্যারান্টরের ফোন') ||
                  line.contains('গ্যারান্টর ফোনঃ') ||
                  line.contains('গ্যারান্টর মোবাইলঃ'))) {
            String phoneText = line
                .replaceAll('গ্যারান্টর ফোন', '')
                .replaceAll('Guarantor Phone', '')
                .replaceAll('গ্যারান্টর মোবাইল', '')
                .replaceAll('Guarantor Mobile', '')
                .replaceAll('গ্যারান্টরের ফোন', '')
                .replaceAll('গ্যারান্টর ফোনঃ', '')
                .replaceAll('গ্যারান্টর মোবাইলঃ', '')
                .replaceAll('ফোন', '')
                .replaceAll('Phone', '')
                .replaceAll('মোবাইল', '')
                .replaceAll('Mobile', '')
                .replaceAll('ঃ', '')
                .replaceAll(':', '')
                .trim();
            phoneText = phoneText
                .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                .trim();

            if (RegExp(r'\d{11}').hasMatch(phoneText) ||
                RegExp(r'\d{3}\s+\d{3}\s+\d{5}').hasMatch(phoneText) ||
                RegExp(r'\d{4}\s+\d{3}\s+\d{4}').hasMatch(phoneText)) {
              guarantorPhone = phoneText
                  .replaceAll(RegExp(r'[^\d\s]'), '')
                  .trim();
            } else if (i + 1 < lines.length) {
              String nextLine = lines[i + 1].trim();
              nextLine = nextLine
                  .replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '')
                  .trim();
              if (RegExp(r'\d{11}').hasMatch(nextLine) ||
                  RegExp(r'\d{3}\s+\d{3}\s+\d{5}').hasMatch(nextLine) ||
                  RegExp(r'\d{4}\s+\d{3}\s+\d{4}').hasMatch(nextLine)) {
                guarantorPhone = nextLine
                    .replaceAll(RegExp(r'[^\d\s]'), '')
                    .trim();
              }
            }
          }
        }
      } else {
        // Clean guarantor name if already parsed
        guarantorName = _cleanName(guarantorName);
      }

      return BangladeshNidInfo(
        nidNumber: nidNumber,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        guarantorName: guarantorName,
        guarantorNidNumber: guarantorNidNumber,
        guarantorAddress: guarantorAddress,
        guarantorPhone: guarantorPhone,
        rawText: extractedText,
      );
    } catch (e) {
      throw Exception('Failed to parse NID information: $e');
    }
  }

  ///Old Nid
  // Extract NID number by taking digit groups until 10 digits total
  // static String _extractNidNumber(String text) {
  //   List<String> groups = text.split(RegExp(r'\s+'));
  //   StringBuffer nidBuf = StringBuffer();
  //   int totalDigits = 0;
  //   for (String group in groups) {
  //     String digits = group.replaceAll(RegExp(r'[^\d]'), '');
  //     if (digits.isNotEmpty && digits.length <= 8) {  // Reasonable group size
  //       if (totalDigits + digits.length > 10) {
  //         break;
  //       }
  //       if (totalDigits > 0) {
  //         nidBuf.write(' ');
  //       }
  //       nidBuf.write(group);  // Preserve original formatting
  //       totalDigits += digits.length;
  //     }
  //   }
  //   if (totalDigits == 10) {
  //     return nidBuf.toString().trim();
  //   }
  //   // Fallback: pure digits first 10
  //   String pureDigits = text.replaceAll(RegExp(r'[^\d]'), '');
  //   if (pureDigits.length >= 10) {
  //     String nid = pureDigits.substring(0, 10);
  //     // Standard format: 3 3 4
  //     return '${nid.substring(0, 3)} ${nid.substring(3, 6)} ${nid.substring(6, 10)}';
  //   }
  //   return '';
  // }
  ///New Nid
  static String _extractNidNumber(String text) {
    List<String> groups = text.split(RegExp(r'\s+'));
    StringBuffer nidBuf = StringBuffer();
    int totalDigits = 0;
    for (String group in groups) {
      String digits = group.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isNotEmpty && digits.length <= 10) {
        // Increased group size limit
        if (totalDigits + digits.length > 15) {
          break;
        }
        if (totalDigits > 0) {
          nidBuf.write(' ');
        }
        nidBuf.write(group); // Preserve original formatting
        totalDigits += digits.length;
        // Stop once we hit a valid NID length
        if (totalDigits == 10 || totalDigits == 14 || totalDigits == 15) {
          break;
        }
      }
    }
    if (totalDigits == 10 || totalDigits == 14 || totalDigits == 15) {
      return nidBuf.toString().trim();
    }
    // Fallback: pure digits, prefer longest matching length starting from index 0
    String pureDigits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (pureDigits.length >= 15) {
      String nid = pureDigits.substring(0, 15);
      // Format as 5 5 5 (common grouping for longer IDs)
      return '${nid.substring(0, 5)} ${nid.substring(5, 10)} ${nid.substring(10, 15)}';
    } else if (pureDigits.length >= 14) {
      String nid = pureDigits.substring(0, 14);
      // Format as 4 5 5
      return '${nid.substring(0, 4)} ${nid.substring(4, 9)} ${nid.substring(9, 14)}';
    } else if (pureDigits.length >= 10) {
      String nid = pureDigits.substring(0, 10);
      // Standard format: 3 3 4
      return '${nid.substring(0, 3)} ${nid.substring(3, 6)} ${nid.substring(6, 10)}';
    }
    return '';
  }

  /// Clean field value based on field type
  static String _cleanFieldValue(String field, String value) {
    value = value.replaceAll(RegExp(r'^[:\s]+|[:\s]+$'), '').trim();
    switch (field) {
      case 'nidNumber':
        return _extractNidNumber(value);
      case 'dateOfBirth':
        // Remove any trailing garbage after date
        var dateMatch = RegExp(
          r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}|\d{2}[/-]\d{2}[/-]\d{4}|\d{4}[/-]\d{2}[/-]\d{2}',
        ).firstMatch(value);
        if (dateMatch != null) {
          return dateMatch.group(0)!;
        }
        return value;
      case 'fullName':
        return _cleanName(value);
      case 'guarantorName':
        return _cleanName(value);
      case 'guarantorNidNumber':
        return _extractNidNumber(value);
      default:
        return value;
    }
  }

  /// Clean name by filtering words: length > 2, starts with uppercase, limit to 4 words
  static String _cleanName(String name) {
    if (name.isEmpty) return name;
    final words = name.split(' ');
    final List<String> cleanedWords = [];
    for (String word in words) {
      word = word.trim().replaceAll(
        RegExp(r'[.,:;!?\s]+$'),
        '',
      ); // Remove trailing punctuation/spaces
      if (word.isNotEmpty &&
          word.length > 2 &&
          (word[0].toUpperCase() == word[0] || word == word.toUpperCase())) {
        cleanedWords.add(word);
      }
      if (cleanedWords.length >= 4) break; // Limit to max 4 words
    }
    return cleanedWords.join(' ');
  }

  /// Check if a line is a potential date
  static bool _isPotentialDate(String line) {
    return RegExp(r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}').hasMatch(line) ||
        RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(line) ||
        RegExp(r'\d{4}[/-]\d{2}[/-]\d{2}').hasMatch(line) ||
        RegExp(r'\d{1,2}\s+\d{1,2}\s+\d{4}').hasMatch(line) ||
        RegExp(r'\d{1,2}\s+\d{4}').hasMatch(line);
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String dateStr) {
    // DD MMM YYYY
    var match = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})',
    ).firstMatch(dateStr);
    if (match != null) {
      int day = int.tryParse(match.group(1)!) ?? 0;
      String monStr = match.group(2)!.toLowerCase();
      int year = int.tryParse(match.group(3)!) ?? 0;
      int month = _monthFromAbbr(monStr);
      if (day > 0 && month > 0 && year > 1900) {
        var dt = DateTime(year, month, day);
        if (dt.day == day && dt.month == month) return dt;
      }
    }

    // DD/MM/YYYY or DD-MM-YYYY
    match = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(dateStr);
    if (match != null) {
      int day = int.tryParse(match.group(1)!) ?? 0;
      int month = int.tryParse(match.group(2)!) ?? 0;
      int year = int.tryParse(match.group(3)!) ?? 0;
      if (day > 0 && month > 0 && month <= 12 && year > 1900) {
        var dt = DateTime(year, month, day);
        if (dt.day == day && dt.month == month) return dt;
      }
    }

    // YYYY/MM/DD or YYYY-MM-DD
    match = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})').firstMatch(dateStr);
    if (match != null) {
      int year = int.tryParse(match.group(1)!) ?? 0;
      int month = int.tryParse(match.group(2)!) ?? 0;
      int day = int.tryParse(match.group(3)!) ?? 0;
      if (day > 0 && month > 0 && month <= 12 && year > 1900) {
        var dt = DateTime(year, month, day);
        if (dt.day == day && dt.month == month) return dt;
      }
    }

    // DD MM YYYY (no separator)
    match = RegExp(r'(\d{1,2})\s+(\d{1,2})\s+(\d{4})').firstMatch(dateStr);
    if (match != null) {
      int day = int.tryParse(match.group(1)!) ?? 0;
      int month = int.tryParse(match.group(2)!) ?? 0;
      int year = int.tryParse(match.group(3)!) ?? 0;
      if (day > 0 && month > 0 && month <= 12 && year > 1900) {
        var dt = DateTime(year, month, day);
        if (dt.day == day && dt.month == month) return dt;
      }
    }

    return null;
  }

  /// Convert month abbreviation to number
  static int _monthFromAbbr(String abbr) {
    switch (abbr) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 0;
    }
  }

  /// Capture image from camera
  static Future<String?> captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return null;
      final file = await ImageCompressionService.ensureForXFile(image);
      return file.path;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

class BangladeshNidInfo {
  final String nidNumber;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String guarantorName;
  final String guarantorNidNumber;
  final String guarantorAddress;
  final String guarantorPhone;
  final String rawText;

  BangladeshNidInfo({
    required this.nidNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.guarantorName,
    required this.guarantorNidNumber,
    required this.guarantorAddress,
    required this.guarantorPhone,
    required this.rawText,
  });

  Map<String, dynamic> toJson() {
    return {
      'nidNumber': nidNumber,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'guarantorName': guarantorName,
      'guarantorNidNumber': guarantorNidNumber,
      'guarantorAddress': guarantorAddress,
      'guarantorPhone': guarantorPhone,
      'rawText': rawText,
    };
  }

  @override
  String toString() {
    return 'BangladeshNidInfo(nidNumber: $nidNumber, fullName: $fullName, dateOfBirth: $dateOfBirth, gender: $gender, address: $address, guarantorName: $guarantorName, guarantorNidNumber: $guarantorNidNumber, guarantorAddress: $guarantorAddress, guarantorPhone: $guarantorPhone)';
  }
}
