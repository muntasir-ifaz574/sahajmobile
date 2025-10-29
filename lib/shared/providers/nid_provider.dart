import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nid_ocr_service.dart';

// NID State
class NidState {
  final bool isLoading;
  final BangladeshNidInfo? nidInfo;
  final String? frontImagePath;
  final String? backImagePath;
  final String? error;
  final String? selectedGender;

  const NidState({
    this.isLoading = false,
    this.nidInfo,
    this.frontImagePath,
    this.backImagePath,
    this.error,
    this.selectedGender,
  });

  NidState copyWith({
    bool? isLoading,
    BangladeshNidInfo? nidInfo,
    String? frontImagePath,
    String? backImagePath,
    String? error,
    String? selectedGender,
  }) {
    return NidState(
      isLoading: isLoading ?? this.isLoading,
      nidInfo: nidInfo ?? this.nidInfo,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      error: error ?? this.error,
      selectedGender: selectedGender ?? this.selectedGender,
    );
  }
}

// NID Notifier
class NidNotifier extends Notifier<NidState> {
  @override
  NidState build() {
    return const NidState();
  }

  Future<void> setFrontImage(String imagePath) async {
    state = state.copyWith(frontImagePath: imagePath, error: null);
    await _processImages();
  }

  Future<void> setBackImage(String imagePath) async {
    state = state.copyWith(backImagePath: imagePath, error: null);
    await _processImages();
  }

  Future<void> _processImages() async {
    if (state.frontImagePath == null || state.backImagePath == null) {
      return; // Wait for both images
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Extract text from both images
      final frontText = await NidOcrService.extractTextFromImage(
        state.frontImagePath!,
      );
      final backText = await NidOcrService.extractTextFromImage(
        state.backImagePath!,
      );

      // Combine both texts for better parsing
      final combinedText = '$frontText\n$backText';

      // Parse NID information
      final nidInfo = await NidOcrService.parseNidInfo(combinedText);

      state = state.copyWith(isLoading: false, nidInfo: nidInfo, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        nidInfo: null,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateSelectedGender(String gender) {
    state = state.copyWith(selectedGender: gender);
  }

  void updateNidNumber(String nidNumber) {
    if (state.nidInfo != null) {
      final updatedNidInfo = BangladeshNidInfo(
        nidNumber: nidNumber,
        fullName: state.nidInfo!.fullName,
        dateOfBirth: state.nidInfo!.dateOfBirth,
        gender: state.nidInfo!.gender,
        address: state.nidInfo!.address,
        guarantorName: state.nidInfo!.guarantorName,
        guarantorNidNumber: state.nidInfo!.guarantorNidNumber,
        guarantorAddress: state.nidInfo!.guarantorAddress,
        guarantorPhone: state.nidInfo!.guarantorPhone,
        rawText: state.nidInfo!.rawText,
      );
      state = state.copyWith(nidInfo: updatedNidInfo);
    }
  }

  void updateFullName(String fullName) {
    if (state.nidInfo != null) {
      final updatedNidInfo = BangladeshNidInfo(
        nidNumber: state.nidInfo!.nidNumber,
        fullName: fullName,
        dateOfBirth: state.nidInfo!.dateOfBirth,
        gender: state.nidInfo!.gender,
        address: state.nidInfo!.address,
        guarantorName: state.nidInfo!.guarantorName,
        guarantorNidNumber: state.nidInfo!.guarantorNidNumber,
        guarantorAddress: state.nidInfo!.guarantorAddress,
        guarantorPhone: state.nidInfo!.guarantorPhone,
        rawText: state.nidInfo!.rawText,
      );
      state = state.copyWith(nidInfo: updatedNidInfo);
    }
  }

  void updateDateOfBirth(String dateOfBirth) {
    if (state.nidInfo != null) {
      final updatedNidInfo = BangladeshNidInfo(
        nidNumber: state.nidInfo!.nidNumber,
        fullName: state.nidInfo!.fullName,
        dateOfBirth: dateOfBirth,
        gender: state.nidInfo!.gender,
        address: state.nidInfo!.address,
        guarantorName: state.nidInfo!.guarantorName,
        guarantorNidNumber: state.nidInfo!.guarantorNidNumber,
        guarantorAddress: state.nidInfo!.guarantorAddress,
        guarantorPhone: state.nidInfo!.guarantorPhone,
        rawText: state.nidInfo!.rawText,
      );
      state = state.copyWith(nidInfo: updatedNidInfo);
    }
  }

  void reset() {
    state = const NidState();
  }
}

// Providers
final nidProvider = NotifierProvider<NidNotifier, NidState>(() {
  return NidNotifier();
});

final nidInfoProvider = Provider<BangladeshNidInfo?>((ref) {
  return ref.watch(nidProvider).nidInfo;
});

final nidLoadingProvider = Provider<bool>((ref) {
  return ref.watch(nidProvider).isLoading;
});

final nidErrorProvider = Provider<String?>((ref) {
  return ref.watch(nidProvider).error;
});
