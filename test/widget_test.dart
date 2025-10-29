import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahajmobile/shared/services/nid_ocr_service.dart';

void main() {
  testWidgets('ProviderScope works correctly', (WidgetTester tester) async {
    // Test that ProviderScope can be created without errors
    final providerScope = ProviderScope(
      child: const MaterialApp(home: Scaffold(body: Text('Test'))),
    );

    await tester.pumpWidget(providerScope);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });

  group('OCR Service Tests', () {
    test('BangladeshNidInfo model works correctly', () {
      final nidInfo = BangladeshNidInfo(
        nidNumber: '1234567890',
        fullName: 'Test User',
        dateOfBirth: 'Jan 1, 1990',
        gender: 'Male',
        address: 'Test Address',
        rawText: 'Raw OCR text',
        guarantorName: '',
        guarantorNidNumber: '',
        guarantorAddress: '',
        guarantorPhone: '',
      );

      expect(nidInfo.nidNumber, equals('1234567890'));
      expect(nidInfo.fullName, equals('Test User'));
      expect(nidInfo.dateOfBirth, equals('Jan 1, 1990'));
      expect(nidInfo.gender, equals('Male'));
      expect(nidInfo.address, equals('Test Address'));
      expect(nidInfo.rawText, equals('Raw OCR text'));
    });

    test('NID parsing with real Bangladesh NID card data', () async {
      const realNidText = '''
        গণপ্রজাতন্ত্রী বাংলাদেশ সরকার
        Government of the People's Republic of Bangladesh
        জাতীয় পরিচয়পত্র
        National ID Card
        
        নাম
        মুনতারিন বিনতে সামিয়া
        Name
        MUNTARIN BINTE SAMIA
        
        পিতা
        মমিনুল হক
        
        মাতা
        হাসনা বানু
        
        Date of Birth
        18 Feb 1998
        
        NID No.
        780 379 4960
      ''';

      final nidInfo = await NidOcrService.parseNidInfo(realNidText);

      expect(nidInfo.nidNumber, equals('780 379 4960'));
      expect(nidInfo.fullName, equals('MUNTARIN BINTE SAMIA'));
      expect(nidInfo.dateOfBirth, equals('18 Feb 1998'));
    });
  });
}
