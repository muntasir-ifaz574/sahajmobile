import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class BkashStatementInfo {
  final String accountName;
  final String accountNumber;

  const BkashStatementInfo({
    required this.accountName,
    required this.accountNumber,
  });
}

class BkashStatementOcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract account name and 11-digit account number from an image or PDF.
  static Future<BkashStatementInfo> extract(String filePath) async {
    final String lower = filePath.toLowerCase();
    String allText = '';
    if (lower.endsWith('.pdf')) {
      allText = await _extractTextFromPdf(filePath);
    } else {
      allText = await _extractTextFromImage(filePath);
    }
    return _parse(allText);
  }

  static Future<String> _extractTextFromImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognized = await _textRecognizer.processImage(inputImage);
    return recognized.text;
  }

  static Future<String> _extractTextFromPdf(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final int pageCount = document.pages.count;
      final int endIndex = pageCount > 3 ? 2 : pageCount - 1;
      String buffer = '';
      if (pageCount > 0) {
        buffer = extractor.extractText(
          startPageIndex: 0,
          endPageIndex: endIndex < 0 ? 0 : endIndex,
        );
      }
      document.dispose();
      return buffer;
    } catch (_) {
      return '';
    }
  }

  static BkashStatementInfo _parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String accountNumber = '';
    String accountName = '';
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Match "bKash Account Number: 017XXXXXXXX" (11 digits)
      final match = RegExp(
        r'Account\s*Number[:\s]*([0-9]{11})',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        accountNumber = match.group(1)!;
        // take previous significant line as name candidate
        for (int k = i - 1; k >= 0 && k >= i - 4; k--) {
          final prev = lines[k];
          if (_looksLikeName(prev)) {
            accountName = prev;
            break;
          }
        }
        if (accountName.isEmpty) {
          // fallback: scan earlier lines for best uppercase name candidate
          final earlier = lines.take(i).toList().reversed;
          accountName = earlier.firstWhere(_looksLikeName, orElse: () => '');
        }
        break;
      }
    }

    // Additional fallback search if number not found in the loop
    if (accountNumber.isEmpty) {
      final match = RegExp(
        r'\b(01\d{9})\b',
      ).firstMatch(text.replaceAll(' ', ''));
      if (match != null) {
        accountNumber = match.group(1)!;
      }
    }

    // NEW: Robust name extraction via pattern matching for "bKash Statement - NAME"
    // This handles cases where name appears at page footers or headers, common in bKash PDFs
    if (accountName.isEmpty) {
      final nameMatch = RegExp(
        r'bKash\s*Statement\s*[-–]\s*([A-Z.\s]{5,30})(?=\s*(Page|\d+|$|bKash))',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      if (nameMatch != null) {
        accountName = nameMatch
            .group(1)!
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ');
      }
    }

    // NEW: Alternative search for name near "User Type: Customer" or top sections
    if (accountName.isEmpty) {
      // Find index of "User Type" line
      final userTypeIndex = lines.indexWhere(
        (l) => l.toLowerCase().contains('user type'),
      );
      if (userTypeIndex != -1) {
        // Look 1-5 lines before for name
        for (int k = userTypeIndex - 1; k >= 0 && k >= userTypeIndex - 5; k--) {
          if (_looksLikeName(lines[k])) {
            accountName = lines[k];
            break;
          }
        }
      }
    }

    // Final fallback for name: strongest uppercase line near top or anywhere
    if (accountName.isEmpty && lines.isNotEmpty) {
      // Broaden search: entire list, but prioritize early lines
      final candidates = lines.where(_looksLikeName).toList();
      if (candidates.isNotEmpty) {
        // Pick the first (most likely top-of-page)
        accountName = candidates.first;
      } else {
        // Ultra-fallback: first uppercase-heavy line
        accountName = lines
            .take(20)
            .firstWhere(
              (l) => RegExp(r'^[A-Z\s\.\-,]{3,}$').hasMatch(l) && l.length > 5,
              orElse: () => '',
            );
      }
    }

    return BkashStatementInfo(
      accountName: accountName,
      accountNumber: accountNumber,
    );
  }

  static bool _looksLikeName(String s) {
    // Accept typical uppercase names including dots and spaces (e.g., "MD. SANTU SIKDER")
    final bool mostlyUpper =
        RegExp(r'^[A-Z .]{3,}$').hasMatch(s) &&
        s.replaceAll(' ', '').length > 5;
    // Filter out noisy headings
    final lower = s.toLowerCase();
    if (lower.contains('bkash') ||
        lower.contains('statement') ||
        lower.contains('user type')) {
      return false;
    }
    return mostlyUpper;
  }
}
