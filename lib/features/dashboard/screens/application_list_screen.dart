import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';

class ApplicationListScreen extends ConsumerStatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  ConsumerState<ApplicationListScreen> createState() =>
      _ApplicationListScreenState();
}

class _BoldValueText extends StatelessWidget {
  final String label;
  final String value;

  const _BoldValueText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationListScreenState extends ConsumerState<ApplicationListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final Set<String> _expandedItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final applications = await ApiService.getCustomerShopList();
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case '1':
        return 'Approved';
      case '2':
        return 'Pending';
      case '3':
        return 'Disapproved';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case '1':
        return AppTheme.successColor;
      case '2':
        return AppTheme.primaryColor;
      case '3':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDownPayment(String? downPayment) {
    if (downPayment == null || downPayment == 'N/A') {
      return 'N/A';
    }
    try {
      final value = double.parse(downPayment);
      return value.round().toString();
    } catch (e) {
      return downPayment;
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString == 'N/A' || dateString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getFilteredApplications(String status) {
    var filtered = _applications
        .where((app) => app['status']?.toString() == status)
        .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final applicant = (app['applicant']?.toString() ?? '').toLowerCase();
        final telephone = (app['telephone']?.toString() ?? '').toLowerCase();
        return applicant.contains(_searchQuery) ||
            telephone.contains(_searchQuery);
      }).toList();
    }

    filtered.sort((a, b) {
      final dateA = _parseDate(a['date']?.toString());
      final dateB = _parseDate(b['date']?.toString());

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Applications',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: _isLoading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Disapproved'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadApplications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (!_isLoading && _error == null) _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApplicationsList('2'), // Pending
                      _buildApplicationsList('1'), // Approved
                      _buildApplicationsList('3'), // Disapproved
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by applicant or telephone...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsList(String status) {
    final filteredApplications = _getFilteredApplications(status);

    if (filteredApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.description_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No applications found matching "${_searchController.text}"'
                  : 'No ${_getStatusText(status)} applications found',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredApplications.length,
        itemBuilder: (context, index) {
          final app = filteredApplications[index];
          return _buildApplicationListItem(app);
        },
      ),
    );
  }

  Widget _buildApplicationListItem(Map<String, dynamic> app) {
    final status = app['status']?.toString();
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final applicant = app['applicant']?.toString() ?? 'N/A';
    final telephone = app['telephone']?.toString() ?? 'N/A';
    final paymentTearm = app['name']?.toString() ?? 'N/A';
    final id = app['id']?.toString() ?? 'N/A';
    final date = app['date']?.toString() ?? 'N/A';
    final brand = app['brand']?.toString() ?? 'N/A';
    final model = app['model']?.toString() ?? 'N/A';
    final salesRate = app['salesRate']?.toString() ?? 'N/A';
    final downPayment = app['downPayment']?.toString() ?? 'N/A';
    final qrCode = app['qr_code']?.toString();
    final isApproved = status == '1';
    final isExpanded = _expandedItems.contains(id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isApproved && qrCode != null && qrCode.isNotEmpty
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expandedItems.remove(id);
                      } else {
                        _expandedItems.add(id);
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        id,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    applicant,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _BoldValueText(label: 'Tel', value: telephone),
                      const SizedBox(height: 2),
                      _BoldValueText(label: 'Date', value: _formatDate(date)),
                      const SizedBox(height: 2),
                      _BoldValueText(label: 'Brand', value: brand),
                      _BoldValueText(label: 'Model', value: model),
                      const SizedBox(height: 2),
                      _BoldValueText(
                        label: 'Payment Term',
                        value: paymentTearm,
                      ),
                      const SizedBox(height: 2),
                      _BoldValueText(label: 'Sales Rate', value: salesRate),
                      const SizedBox(height: 2),
                      _BoldValueText(
                        label: 'Down Payment',
                        value: _formatDownPayment(downPayment),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                if (isApproved && qrCode != null && qrCode.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 16,
                    child: Icon(
                      Icons.qr_code,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                if (isApproved && qrCode != null && qrCode.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 16,
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),

          if (isApproved && qrCode != null && qrCode.isNotEmpty)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // color: AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black.withValues(alpha: 0.05),
                        //     blurRadius: 5,
                        //     offset: const Offset(0, 2),
                        //   ),
                        // ],
                      ),
                      child: CachedNetworkImage(
                        imageUrl: qrCode,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
        ],
      ),
    );
  }
}
