import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/application_list_provider.dart';

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
  late TabController _tabController;
  final Set<String> _expandedItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    // Load applications when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialStatus =
          ApplicationListNotifier.statusOrder[_tabController.index];
      ref
          .read(applicationListProvider.notifier)
          .loadApplications(status: initialStatus);
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final status = ApplicationListNotifier.statusOrder[_tabController.index];
    ref.read(applicationListProvider.notifier).loadApplications(status: status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFinancialInfo(String id) async {
    final notifier = ref.read(applicationListProvider.notifier);
    await notifier.toggleFinancialInfo(id);

    if (!mounted) return;
    final state = ref.read(applicationListProvider);
    final error = state.financialInfoErrors[id];

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financial info unavailable')),
      );
    } else if (!state.financialInfoData.containsKey(id) &&
        !state.financialInfoExpanded.contains(id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Financial info not found')));
    }
  }

  void _copyFinancialInfo(String id) {
    final notifier = ref.read(applicationListProvider.notifier);
    final data = notifier.getFinancialInfo(id);
    if (data.isEmpty) return;
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Financial info copied')));
  }

  Future<void> _shareFinancialInfo(String id) async {
    final notifier = ref.read(applicationListProvider.notifier);
    final data = notifier.getFinancialInfo(id);
    if (data.isEmpty) return;
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
    final state = ref.watch(applicationListProvider);
    final notifier = ref.read(applicationListProvider.notifier);

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
        bottom: state.error != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                labelStyle: TextStyle(fontSize: 12),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Disapproved'),
                ],
              ),
      ),
      body: state.error != null
          ? _buildErrorState(state.error!, notifier)
          : Column(
              children: [
                if (state.isLoading)
                  const SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApplicationsList('2', state.isLoading),
                      _buildApplicationsList('4', state.isLoading),
                      _buildApplicationsList('1', state.isLoading),
                      _buildApplicationsList('3', state.isLoading),
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

  Widget _buildApplicationsList(String status, bool isLoading) {
    final notifier = ref.read(applicationListProvider.notifier);
    final filteredApplications = notifier.getFilteredApplications(
      status,
      _searchQuery,
    );
    final hasLoaded = notifier.hasLoadedStatus(status);

    if (!hasLoaded) {
      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No data loaded for this status yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => notifier.loadApplications(status: status),
              child: const Text('Load now'),
            ),
          ],
        ),
      );
    }

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
                  : 'No ${ApplicationListNotifier.getStatusText(status)} applications found',
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
      onRefresh: () => notifier.loadApplications(status: status),
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
    final statusText = ApplicationListNotifier.getStatusText(status);
    final statusColor = ApplicationListNotifier.getStatusColor(status);
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
                      _BoldValueText(
                        label: 'Date',
                        value: ApplicationListNotifier.formatDate(date),
                      ),
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
                        value: ApplicationListNotifier.formatDownPayment(
                          downPayment,
                        ),
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
    final notifier = ref.read(applicationListProvider.notifier);
    final isExpanded = notifier.isFinancialInfoExpanded(id);
    final isLoading = notifier.isFinancialInfoLoading(id);
    final error = notifier.getFinancialInfoError(id);
    final data = notifier.getFinancialInfo(id);
    final dataOrNull = data.isEmpty ? null : data;

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
          secondChild: _buildFinancialInfoContent(id, dataOrNull, error),
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
              onPressed: () async {
                await _toggleFinancialInfo(id);
              },
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
      final items = ApplicationListNotifier.extractFinancialInfoItems(data);
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

  Widget _buildErrorState(String error, ApplicationListNotifier notifier) {
    final currentStatus =
        ApplicationListNotifier.statusOrder[_tabController.index];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => notifier.loadApplications(status: currentStatus),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
