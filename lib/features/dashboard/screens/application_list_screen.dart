import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
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

class _FinancialInfoItem {
  final String label;
  final String value;

  const _FinancialInfoItem({required this.label, required this.value});
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
  final Map<String, String> _financialInfoData = {};
  final Map<String, String> _financialInfoErrors = {};
  final Set<String> _financialInfoLoading = {};
  final Set<String> _financialInfoExpanded = {};

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

  List<_FinancialInfoItem> _extractFinancialInfoItems(String? data) {
    if (data == null || data.trim().isEmpty) {
      return const [];
    }

    final lines = data
        .replaceAll('\t', ' ')
        .split(RegExp(r'\r\n|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final entries = <MapEntry<String, String>>[];
    for (final line in lines) {
      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) continue;
      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      entries.add(MapEntry(key, value));
    }

    MapEntry<String, String>? findEntry(List<String> needles) {
      for (final entry in entries) {
        final keyLower = entry.key.toLowerCase();
        if (needles.any((needle) => keyLower.contains(needle))) {
          return entry;
        }
      }
      return null;
    }

    final items = <_FinancialInfoItem>[];

    void addItem({
      required List<String> keys,
      required String label,
      String Function(MapEntry<String, String>)? valueBuilder,
    }) {
      final entry = findEntry(keys);
      if (entry == null || entry.key.isEmpty) return;
      final value = valueBuilder != null
          ? valueBuilder(entry)
          : entry.value.trim();
      if (value.isEmpty) return;
      items.add(_FinancialInfoItem(label: label, value: value));
    }

    addItem(keys: ['emi plan'], label: 'EMI Plan');

    addItem(keys: ['mrp'], label: 'Cell Phone Price');

    addItem(
      keys: ['emi charge'],
      label: 'EMI Charge',
      valueBuilder: (entry) => entry.value.replaceAll('(+) ', '').trim(),
    );

    addItem(
      keys: ['net price with emi charge'],
      label: 'Total Price with EMI Charge',
    );

    addItem(
      keys: ['down-payment', 'down payment'],
      label: 'Down Payment',
      valueBuilder: (entry) {
        final amount = entry.value;
        final percentMatch = RegExp(
          r'([0-9]+(?:\.[0-9]+)?)\s*%',
        ).firstMatch(entry.key);
        if (percentMatch != null) {
          final percent = double.tryParse(percentMatch.group(1) ?? '');
          if (percent != null) {
            final formatted = percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2);
            return '$amount ($formatted%)';
          }
          return '$amount (${percentMatch.group(1)}%)';
        }
        return amount;
      },
    );

    addItem(
      keys: ['net instalment amount', 'net installment amount'],
      label: 'Total Installment Amount',
    );

    final paymentEntry = findEntry(['weekly payment', 'monthly payment']);
    if (paymentEntry != null && paymentEntry.key.isNotEmpty) {
      final label = paymentEntry.key.toLowerCase().contains('weekly')
          ? 'Weekly Payment'
          : 'Monthly Payment';
      items.add(
        _FinancialInfoItem(label: label, value: paymentEntry.value.trim()),
      );
    }

    addItem(
      keys: ['instalment start date', 'installment start date'],
      label: 'Installment Start Date',
    );

    addItem(keys: ['emi payment portal'], label: 'EMI Payment Portal');

    return items;
  }

  Future<void> _toggleFinancialInfo(String id) async {
    if (_financialInfoExpanded.contains(id)) {
      setState(() {
        _financialInfoExpanded.remove(id);
      });
      return;
    }

    if (_financialInfoData.containsKey(id)) {
      setState(() {
        _financialInfoExpanded.add(id);
      });
      return;
    }

    setState(() {
      _financialInfoLoading.add(id);
      _financialInfoErrors.remove(id);
    });

    try {
      final info = await ApiService.getFinancialInfo(applicationId: id);
      if (!mounted) return;
      final trimmed = info.trim();
      final isEmptyResult =
          trimmed.isEmpty ||
          trimmed == '{}' ||
          trimmed == '[]' ||
          trimmed.toLowerCase() == 'null';
      if (isEmptyResult) {
        setState(() {
          _financialInfoData.remove(id);
          _financialInfoErrors.remove(id);
          _financialInfoExpanded.remove(id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial info not found')),
        );
        return;
      }
      setState(() {
        _financialInfoErrors.remove(id);
        _financialInfoData[id] = info;
        _financialInfoExpanded.add(id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _financialInfoErrors[id] = e.toString();
        _financialInfoExpanded.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financial info unavailable')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _financialInfoLoading.remove(id);
      });
    }
  }

  void _copyFinancialInfo(String id) {
    final data = _financialInfoData[id];
    if (data == null) return;
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Financial info copied')));
  }

  Future<void> _shareFinancialInfo(String id) async {
    final data = _financialInfoData[id];
    if (data == null) return;
    try {
      await Share.share(data, subject: 'Financial Information');
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sharing is not supported on this device'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share: $e')));
    }
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
          _buildFinancialInfoSection(id),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoSection(String id) {
    final isExpanded = _financialInfoExpanded.contains(id);
    final isLoading = _financialInfoLoading.contains(id);
    final error = _financialInfoErrors[id];
    final data = _financialInfoData[id];

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    isExpanded ? 'Hide financial info' : 'Financial info',
                  ),
                  onPressed: () => _toggleFinancialInfo(id),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildFinancialInfoContent(id, data, error),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildFinancialInfoContent(String id, String? data, String? error) {
    Widget child;
    if (error != null) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load financial info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _toggleFinancialInfo(id),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    } else if (data == null) {
      child = const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Fetching financial info...',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      );
    } else {
      final items = _extractFinancialInfoItems(data);
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text(
              'Financial info not available.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText.rich(
                  TextSpan(
                    text: '${item.label}: ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: item.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _copyFinancialInfo(id),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _shareFinancialInfo(id),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: child,
    );
  }
}
