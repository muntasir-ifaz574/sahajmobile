import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

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

      String nidNumber = '';
      String fullName = '';
      String dateOfBirth = '';
      String gender = '';
      String address = '';
      String guarantorName = '';
      String guarantorNidNumber = '';
      String guarantorAddress = '';
      String guarantorPhone = '';

      // Parse NID Number - Look for "NID No." pattern
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains('NID No') || line.contains('NID No.')) {
          // Look for NID number in the same line or next line
          String nidText = line
              .replaceAll('NID No', '')
              .replaceAll('NID No.', '')
              .trim();
          if (nidText.isNotEmpty && nidText != '.') {
            nidNumber = nidText;
          } else if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty && nextLine != '.') {
              nidNumber = nextLine;
            }
          }
          break;
        }
      }

      // Fallback: Look for number pattern with spaces (like "780 379 4960")
      if (nidNumber.isEmpty) {
        for (String line in lines) {
          if (RegExp(r'\d{3}\s+\d{3}\s+\d{4}').hasMatch(line)) {
            nidNumber = line.trim();
            break;
          }
        }
      }

      // Parse Name - Look for both Bengali and English, prioritize English
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains('নাম') || line.contains('Name')) {
          // Look for English name first
          for (int j = i + 1; j < lines.length && j < i + 5; j++) {
            String nameLine = lines[j].trim();
            if (nameLine.isNotEmpty &&
                !nameLine.contains('পিতা') &&
                !nameLine.contains('মাতা') &&
                !nameLine.contains('Date') &&
                !nameLine.contains('NID') &&
                !nameLine.contains('Name') && // Skip the "Name" label
                !RegExp(r'^\d+$').hasMatch(nameLine) &&
                !nameLine.contains(RegExp(r'[\u0980-\u09FF]'))) {
              // Not Bengali
              fullName = nameLine;
              break;
            }
          }

          // If no English name found, use Bengali name
          if (fullName.isEmpty && i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (nextLine.contains(RegExp(r'[\u0980-\u09FF]'))) {
              fullName = nextLine;
            }
          }
          break;
        }
      }

      // Parse Date of Birth - Enhanced detection with better filtering
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        // Look for explicit date labels (prioritize birth date over issue date)
        if (line.contains('Date of Birth') ||
            line.contains('জন্ম তারিখ') ||
            line.contains('DOB') ||
            line.contains('Birth')) {
          // Check current line for date
          if (RegExp(r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}').hasMatch(line) ||
              RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(line) ||
              RegExp(r'\d{4}[/-]\d{2}[/-]\d{2}').hasMatch(line)) {
            dateOfBirth = line.trim();
            break;
          }
          // Check next line for date
          if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (RegExp(r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}').hasMatch(nextLine) ||
                RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(nextLine) ||
                RegExp(r'\d{4}[/-]\d{2}[/-]\d{2}').hasMatch(nextLine)) {
              dateOfBirth = nextLine;
              break;
            }
          }
        }
      }

      // Enhanced fallback: Look for various date patterns but exclude issue dates
      if (dateOfBirth.isEmpty) {
        List<String> potentialDates = [];

        for (int i = 0; i < lines.length; i++) {
          String line = lines[i];

          // Common date formats
          if (RegExp(r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}').hasMatch(line) ||
              RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}').hasMatch(line) ||
              RegExp(r'\d{4}[/-]\d{2}[/-]\d{2}').hasMatch(line) ||
              RegExp(r'\d{1,2}\s+\d{1,2}\s+\d{4}').hasMatch(line) ||
              RegExp(r'\d{1,2}\s+\d{4}').hasMatch(line)) {
            // Check context around the date to determine if it's birth date or issue date
            bool isLikelyBirthDate = true;

            // Check current line
            if (line.toLowerCase().contains('issue') ||
                line.toLowerCase().contains('issued') ||
                line.toLowerCase().contains('valid') ||
                line.toLowerCase().contains('expiry') ||
                line.toLowerCase().contains('expire')) {
              isLikelyBirthDate = false;
            }

            // Check previous line for context
            if (i > 0) {
              String prevLine = lines[i - 1].toLowerCase();
              if (prevLine.contains('issue') ||
                  prevLine.contains('issued') ||
                  prevLine.contains('valid') ||
                  prevLine.contains('expiry') ||
                  prevLine.contains('expire')) {
                isLikelyBirthDate = false;
              }
            }

            // Check next line for context
            if (i + 1 < lines.length) {
              String nextLine = lines[i + 1].toLowerCase();
              if (nextLine.contains('issue') ||
                  nextLine.contains('issued') ||
                  nextLine.contains('valid') ||
                  nextLine.contains('expiry') ||
                  nextLine.contains('expire')) {
                isLikelyBirthDate = false;
              }
            }

            if (isLikelyBirthDate) {
              potentialDates.add(line.trim());
            }
          }
        }

        // Use the first potential birth date found
        if (potentialDates.isNotEmpty) {
          dateOfBirth = potentialDates.first;
        }
      }

      // Parse Gender - Look for gender indicators
      for (String line in lines) {
        if (line.toLowerCase().contains('male') ||
            line.toLowerCase().contains('female') ||
            line.contains('পুরুষ') ||
            line.contains('মহিলা')) {
          gender = line.trim();
          break;
        }
      }

      // Parse Address - Look for address indicators
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.contains('ঠিকানা') || line.contains('Address')) {
          if (i + 1 < lines.length) {
            address = lines[i + 1].trim();
            break;
          }
        }
      }

      // Parse Guarantor Information - Enhanced detection
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        // Look for guarantor name patterns
        if (line.contains('গ্যারান্টর') ||
            line.contains('Guarantor') ||
            line.contains('গ্যারান্টর নাম') ||
            line.contains('Guarantor Name') ||
            line.contains('গ্যারান্টরের নাম') ||
            line.contains('গ্যারান্টর নামঃ')) {
          // Extract name from current line
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

          if (nameText.isNotEmpty && nameText != '.' && nameText.length > 2) {
            guarantorName = nameText;
          } else if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
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
        }

        // Look for guarantor NID number
        if (line.contains('গ্যারান্টর NID') ||
            line.contains('Guarantor NID') ||
            line.contains('গ্যারান্টর NID No') ||
            line.contains('Guarantor NID No') ||
            line.contains('গ্যারান্টর NID নং') ||
            line.contains('গ্যারান্টর NIDঃ')) {
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

          if (RegExp(r'\d{3}\s+\d{3}\s+\d{4}').hasMatch(nidText) ||
              RegExp(r'\d{10}').hasMatch(nidText)) {
            guarantorNidNumber = nidText;
          } else if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (RegExp(r'\d{3}\s+\d{3}\s+\d{4}').hasMatch(nextLine) ||
                RegExp(r'\d{10}').hasMatch(nextLine)) {
              guarantorNidNumber = nextLine;
            }
          }
        }

        // Look for guarantor address
        if (line.contains('গ্যারান্টর ঠিকানা') ||
            line.contains('Guarantor Address') ||
            line.contains('গ্যারান্টরের ঠিকানা') ||
            line.contains('গ্যারান্টর ঠিকানাঃ')) {
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

          if (addressText.isNotEmpty && addressText.length > 5) {
            guarantorAddress = addressText;
          } else if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty &&
                !nextLine.contains('ফোন') &&
                !nextLine.contains('Phone') &&
                !RegExp(r'^\d+$').hasMatch(nextLine) &&
                nextLine.length > 5) {
              guarantorAddress = nextLine;
            }
          }
        }

        // Look for guarantor phone
        if (line.contains('গ্যারান্টর ফোন') ||
            line.contains('Guarantor Phone') ||
            line.contains('গ্যারান্টর মোবাইল') ||
            line.contains('Guarantor Mobile') ||
            line.contains('গ্যারান্টরের ফোন') ||
            line.contains('গ্যারান্টর ফোনঃ') ||
            line.contains('গ্যারান্টর মোবাইলঃ')) {
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

          if (RegExp(r'\d{11}').hasMatch(phoneText) ||
              RegExp(r'\d{3}\s+\d{3}\s+\d{5}').hasMatch(phoneText) ||
              RegExp(r'\d{4}\s+\d{3}\s+\d{4}').hasMatch(phoneText)) {
            guarantorPhone = phoneText;
          } else if (i + 1 < lines.length) {
            String nextLine = lines[i + 1].trim();
            if (RegExp(r'\d{11}').hasMatch(nextLine) ||
                RegExp(r'\d{3}\s+\d{3}\s+\d{5}').hasMatch(nextLine) ||
                RegExp(r'\d{4}\s+\d{3}\s+\d{4}').hasMatch(nextLine)) {
              guarantorPhone = nextLine;
            }
          }
        }
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

  /// Capture image from camera
  static Future<String?> captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image?.path;
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
