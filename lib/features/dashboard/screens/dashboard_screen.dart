import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/services/api_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Agent',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context, ref),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // // Date Filter Tabs
              // _buildDateFilterTabs(),
              //
              // const SizedBox(height: 24),

              // Sales Data Section
              _buildSalesDataSection(),

              const SizedBox(height: 24),

              // Loan Data Section
              // _buildLoanDataSection(),

              // const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(context),

              const SizedBox(height: 24),

              // Slider Banner (hidden if no data)
              _buildSliderSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<String?>>(
              future: Future.wait([
                StorageService.getUsername(),
                StorageService.getShopId(),
              ]),
              builder: (context, snapshot) {
                final username = snapshot.data != null
                    ? snapshot.data![0]
                    : null;
                final shopId = snapshot.data != null ? snapshot.data![1] : null;
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: SvgPicture.asset(
                            'assets/images/SAHAJMOBILE LOGO.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username ?? 'Agent',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shopId != null ? 'Shop ID: $shopId' : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Dashboard'),
                    onTap: () => context.pop(),
                  ),
                  const Divider(),
                  ExpansionTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Contacts'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined, size: 20),
                        title: const Text('Email'),
                        subtitle: const Text('info@sahajmobile.com'),
                        onTap: () => _launchEmail('info@sahajmobile.com'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, size: 20),
                        title: const Text('Phone 1'),
                        subtitle: const Text('+880 199 1160538'),
                        onTap: () => _launchPhone('+8801991160538'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, size: 20),
                        title: const Text('Phone 2'),
                        subtitle: const Text('+880 9666753953'),
                        onTap: () => _launchPhone('+8809666753953'),
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Address'),
                    subtitle: const Text(
                      'Apartments # 4C, RUBAIYAT\nHouse #15, Road #24 CWN(C)\nGulshan-2, Dhaka-1212',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    onTap: () =>
                        _launchMap('https://maps.app.goo.gl/gqrdASTVKhJmnqdg9'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () => _launchUrl(
                      'https://sahajmobile.org/assets/files/Privacy-Policy.pdf',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Refund Policy'),
                    onTap: () => _launchUrl(
                      'https://sahajmobile.org/assets/files/Refund-Policy.pdf',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms and Conditions'),
                    onTap: () => _launchUrl(
                      'https://sahajmobile.org/assets/files/Terms-Conditions.pdf',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Beta Version 0.0.3',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error if email app is not available
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error if phone app is not available
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchMap(String url) async {
    final Uri mapUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error if maps app is not available
      debugPrint('Error launching map: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error if browser is not available
      debugPrint('Error launching URL: $e');
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About SahajMobile'),
          content: SingleChildScrollView(
            child: Text(
              'At SahajMobile, we are driven by the vision of making the latest mobile phone technology accessible to everyone.\n\n'
              'Founded in 2023, our company has established itself as an innovative financial service provider for the mobile technology sector of Bangladesh. We specialize in offering customer-centric Equated Monthly Installment (EMI) plans, enabling a wider demographic to own smartphones while reducing the burden of upfront costs.\n\n'
              'Our approach is rooted in understanding the needs of our customers, many of whom are entering the digital world for the first time. By removing financial barriers, we aim to empower individuals and communities with the tools necessary for embracing the digital era.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildDateTab('Today', true),
          _buildDateTab('Yesterday', false),
          _buildDateTab('7 Days', false),
          _buildDateTab('30 Days', false),
        ],
      ),
    );
  }

  Widget _buildDateTab(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Sales Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            // TextButton(
            //   onPressed: () {
            //     // TODO: Navigate to sales details
            //   },
            //   child: const Text(
            //     'Details >',
            //     style: TextStyle(
            //       color: AppTheme.primaryColor,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: ApiService.getDashboardCounts(),
          builder: (context, snapshot) {
            final pending =
                snapshot.data?['tot_pending_cust']?.toString() ?? '0';
            final approved =
                snapshot.data?['tot_approve_cust']?.toString() ?? '0';
            final disapproved =
                snapshot.data?['tot_disapprove_cust']?.toString() ?? '0';
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDataCard('TOTAL PENDING', pending, AppTheme.primaryColor),
                _buildDataCard(
                  'TOTAL APPROVED',
                  approved,
                  AppTheme.successColor,
                ),
                _buildDataCard(
                  'TOTAL DISAPPROVED',
                  disapproved,
                  AppTheme.errorColor,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Widget _buildLoanDataSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Loan Data',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       GridView.count(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         crossAxisCount: 2,
  //         childAspectRatio: 1.5,
  //         crossAxisSpacing: 12,
  //         mainAxisSpacing: 12,
  //         children: [
  //           _buildLoanCard(
  //             'OVERDUE',
  //             '0>',
  //             AppTheme.errorColor,
  //             'Repaid Today: 0',
  //           ),
  //           _buildLoanCard(
  //             'DUE TODAY',
  //             '0>',
  //             AppTheme.textPrimary,
  //             'Repaid Today: 0',
  //           ),
  //           _buildLoanCard('DUE IN 1 DAY', '0>', AppTheme.textPrimary, null),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDataCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(
    String label,
    String value,
    Color valueColor,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildEmiCalculatorButton(context),
        const SizedBox(height: 15),
        _buildActionButton(
          context,
          'Create New Application',
          Icons.add_circle_outline,
          () {
            context.go('/installment/product-selection');
          },
        ),
        const SizedBox(height: 15),
        _buildActionButton(
          context,
          'Application',
          Icons.description_outlined,
          () {
            context.go('/dashboard/applications');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection() {
    return FutureBuilder<List<String>>(
      future: ApiService.getSliderImages(),
      builder: (context, snapshot) {
        final images = snapshot.data ?? const <String>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (images.isEmpty) {
          // Do not show the section if result is empty
          return const SizedBox.shrink();
        }
        return _SliderBanner(images: images);
      },
    );
  }

  Widget _buildEmiCalculatorButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.12),
            AppTheme.primaryColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openEmiCalculator(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calculate_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'EMI Calculator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Calculate installments and repayment quickly',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _openEmiCalculator(BuildContext context) {
    _launchUrlInApp('https://sm-calculator-teal.vercel.app/');
  }
}

Future<void> _launchUrlInApp(String url) async {
  final Uri uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  } catch (e) {
    debugPrint('Error opening URL: $e');
  }
}

class _SliderBanner extends StatefulWidget {
  final List<String> images;
  const _SliderBanner({required this.images});

  @override
  State<_SliderBanner> createState() => _SliderBannerState();
}

class _SliderBannerState extends State<_SliderBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    // Auto-slide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  void _startAutoSlide() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      _currentPage = (_currentPage + 1) % widget.images.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.05),
      //       blurRadius: 10,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final url = widget.images[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Dots indicator
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryColor : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
