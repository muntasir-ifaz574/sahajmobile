import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/application/screens/address_info_screen.dart';
import '../../features/application/screens/guarantor_info_screen.dart';
import '../../features/application/screens/job_income_screen.dart';
import '../../features/application/screens/machine_info_screen.dart';
import '../../features/approval/screens/approval_status_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/contract/screens/activation_progress_screen.dart';
import '../../features/contract/screens/online_contract_screen.dart';
import '../../features/contract/screens/pre_enroll_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/installment/screens/confirm_information_screen.dart';
import '../../features/installment/screens/installment_plan_screen.dart';
import '../../features/installment/screens/payment_terms_screen.dart';
import '../../features/installment/screens/product_selection_screen.dart';
import '../../features/verification/screens/confirm_id_info_screen.dart';
import '../../features/verification/screens/upload_id_card_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(Ref ref) {
    // Rebuild redirects when auth state changes without recreating router
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefresh(ref),
    redirect: (context, state) {
      // Always read the latest auth state when redirect runs
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final currentLocation = state.uri.toString();

      // Don't redirect if still loading
      if (isLoading) return null;

      // Redirect to login if not authenticated and not on auth pages
      if (!isAuthenticated &&
          !currentLocation.startsWith('/splash') &&
          !currentLocation.startsWith('/onboarding') &&
          !currentLocation.startsWith('/login')) {
        return '/login';
      }

      // Redirect to dashboard if authenticated and on auth pages
      if (isAuthenticated &&
          (currentLocation == '/login' ||
              currentLocation.startsWith('/splash') ||
              currentLocation.startsWith('/onboarding'))) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Splash and Onboarding
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Main App
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Installment Plan Flow
      GoRoute(
        path: '/installment/product-selection',
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      GoRoute(
        path: '/installment/payment-terms',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final modelFromQuery = qp['model'];
          final priceFromQuery = qp['price'];
          final brandFromQuery = qp['brand'];
          final extra = state.extra as Map<String, dynamic>?;
          final model = modelFromQuery ?? extra?['model']?.toString();
          final price = priceFromQuery ?? extra?['price']?.toString();
          final brand = brandFromQuery ?? extra?['brand']?.toString();
          return PaymentTermsScreen(model: model, price: price, brand: brand);
        },
      ),
      GoRoute(
        path: '/installment/plan',
        builder: (context, state) => const InstallmentPlanScreen(),
      ),
      GoRoute(
        path: '/installment/confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ConfirmInformationScreen(
            paymentTerm: extra?['paymentTerm']?.toString(),
            totalPrice: extra?['totalPrice'] as double?,
            downPayment: extra?['downPayment'] as double?,
            totalOutstanding: extra?['totalOutstanding'] as double?,
            monthlyPayment: extra?['monthlyPayment'] as double?,
            months: extra?['months'] as int?,
          );
        },
      ),

      // Verification Flow
      GoRoute(
        path: '/verification/upload-id',
        builder: (context, state) => const UploadIdCardScreen(),
      ),
      GoRoute(
        path: '/verification/confirm-info',
        builder: (context, state) => const ConfirmIdInfoScreen(),
      ),

      // Application Forms
      GoRoute(
        path: '/application/address',
        builder: (context, state) => const AddressInfoScreen(),
      ),
      GoRoute(
        path: '/application/job-income',
        builder: (context, state) => const JobIncomeScreen(),
      ),
      GoRoute(
        path: '/application/guarantor',
        builder: (context, state) => const GuarantorInfoScreen(),
      ),
      GoRoute(
        path: '/application/machine',
        builder: (context, state) => const MachineInfoScreen(),
      ),

      // Contract Flow
      GoRoute(
        path: '/contract/online',
        builder: (context, state) => const OnlineContractScreen(),
      ),
      GoRoute(
        path: '/contract/pre-enroll',
        builder: (context, state) => const PreEnrollScreen(),
      ),
      GoRoute(
        path: '/contract/activation',
        builder: (context, state) => const ActivationProgressScreen(),
      ),

      // Approval
      GoRoute(
        path: '/approval/status',
        builder: (context, state) => const ApprovalStatusScreen(),
      ),
    ],
  );
});
