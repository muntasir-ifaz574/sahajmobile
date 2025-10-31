import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

              // Notice Board
              _buildNoticeBoard(),
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
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => context.go('/dashboard'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              subtitle: const Text('help@sahajmobile.org'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
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
            final pending = snapshot.data?['tot_pending_cust']?.toString() ?? '0';
            final approved = snapshot.data?['tot_approve_cust']?.toString() ?? '0';
            final disapproved = snapshot.data?['tot_disapprove_cust']?.toString() ?? '0';
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDataCard('TOTAL PENDING', pending, AppTheme.primaryColor),
                _buildDataCard('TOTAL APPROVED', approved, AppTheme.successColor,),
                _buildDataCard('TOTAL DISAPPROVED', disapproved, AppTheme.errorColor,),
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
        _buildActionButton(
          context,
          'Create New Application',
          Icons.add_circle_outline,
          () {
            context.go('/installment/product-selection');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'Application',
          Icons.description_outlined,
          () {
            // TODO: Navigate to application
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

  Widget _buildNoticeBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: const Text(
        'Notice Board',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
