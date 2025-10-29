import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends Notifier<AuthState> {
  bool _initialized = false;
  @override
  AuthState build() {
    final current = const AuthState();
    // Restore session once
    if (!_initialized) {
      _initialized = true;
      _restoreSession();
    }
    return current;
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = LoginRequest(username: username, password: password);
      final success = await ApiService.login(request);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: success,
        user: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Log error but continue with logout
    } finally {
      // Nothing to clear for token-based auth right now
      state = const AuthState();
    }
  }

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await ApiService.getProfile();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _restoreSession() async {
    try {
      final loggedIn = await StorageService.isLoggedIn();
      if (loggedIn) {
        state = state.copyWith(isAuthenticated: true, isLoading: false);
      }
    } catch (_) {
      // ignore
    }
  }
}

// Providers
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});
