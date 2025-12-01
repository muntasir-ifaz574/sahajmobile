import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';

// Financial Info Item
class FinancialInfoItem {
  final String label;
  final String value;

  const FinancialInfoItem({required this.label, required this.value});
}

// Application List State
class ApplicationListState {
  static const _undefined = Object();

  final Map<String, List<Map<String, dynamic>>> applicationsByStatus;
  final bool isLoading;
  final String? error;
  final Map<String, String> financialInfoData;
  final Map<String, String> financialInfoErrors;
  final Set<String> financialInfoLoading;
  final Set<String> financialInfoExpanded;

  const ApplicationListState({
    this.applicationsByStatus = const {},
    this.isLoading = false,
    this.error,
    this.financialInfoData = const {},
    this.financialInfoErrors = const {},
    this.financialInfoLoading = const {},
    this.financialInfoExpanded = const {},
  });

  ApplicationListState copyWith({
    Map<String, List<Map<String, dynamic>>>? applicationsByStatus,
    bool? isLoading,
    Object? error = _undefined,
    Map<String, String>? financialInfoData,
    Map<String, String>? financialInfoErrors,
    Set<String>? financialInfoLoading,
    Set<String>? financialInfoExpanded,
  }) {
    return ApplicationListState(
      applicationsByStatus: applicationsByStatus ?? this.applicationsByStatus,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _undefined) ? this.error : error as String?,
      financialInfoData: financialInfoData ?? this.financialInfoData,
      financialInfoErrors: financialInfoErrors ?? this.financialInfoErrors,
      financialInfoLoading: financialInfoLoading ?? this.financialInfoLoading,
      financialInfoExpanded:
          financialInfoExpanded ?? this.financialInfoExpanded,
    );
  }
}

// Application List Notifier
class ApplicationListNotifier extends Notifier<ApplicationListState> {
  static const List<String> statusOrder = ['2', '4', '1', '3'];

  @override
  ApplicationListState build() {
    // Don't call async function in build, it will be called from the screen
    return const ApplicationListState();
  }

  Future<void> loadApplications({String status = '2'}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final applications = await ApiService.getCustomerShopList(status: status);
      final updatedMap = Map<String, List<Map<String, dynamic>>>.from(
        state.applicationsByStatus,
      );
      updatedMap[status] = applications;

      state = state.copyWith(
        applicationsByStatus: updatedMap,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleFinancialInfo(String id) async {
    // If already expanded, collapse it
    if (state.financialInfoExpanded.contains(id)) {
      final newExpanded = Set<String>.from(state.financialInfoExpanded);
      newExpanded.remove(id);
      state = state.copyWith(financialInfoExpanded: newExpanded);
      return;
    }

    // If data already exists, just expand it
    if (state.financialInfoData.containsKey(id)) {
      final newExpanded = Set<String>.from(state.financialInfoExpanded);
      newExpanded.add(id);
      state = state.copyWith(financialInfoExpanded: newExpanded);
      return;
    }

    // Start loading
    final newLoading = Set<String>.from(state.financialInfoLoading);
    newLoading.add(id);
    final newErrors = Map<String, String>.from(state.financialInfoErrors);
    newErrors.remove(id);
    state = state.copyWith(
      financialInfoLoading: newLoading,
      financialInfoErrors: newErrors,
    );

    try {
      final info = await ApiService.getFinancialInfo(applicationId: id);
      final trimmed = info.trim();
      final isEmptyResult =
          trimmed.isEmpty ||
          trimmed == '{}' ||
          trimmed == '[]' ||
          trimmed.toLowerCase() == 'null';

      if (isEmptyResult) {
        final newData = Map<String, String>.from(state.financialInfoData);
        newData.remove(id);
        final newExpanded = Set<String>.from(state.financialInfoExpanded);
        newExpanded.remove(id);
        final newLoadingSet = Set<String>.from(state.financialInfoLoading);
        newLoadingSet.remove(id);
        state = state.copyWith(
          financialInfoData: newData,
          financialInfoExpanded: newExpanded,
          financialInfoLoading: newLoadingSet,
        );
        return;
      }

      final newData = Map<String, String>.from(state.financialInfoData);
      newData[id] = info;
      final newExpanded = Set<String>.from(state.financialInfoExpanded);
      newExpanded.add(id);
      final newLoadingSet = Set<String>.from(state.financialInfoLoading);
      newLoadingSet.remove(id);
      final newErrorsMap = Map<String, String>.from(state.financialInfoErrors);
      newErrorsMap.remove(id);
      state = state.copyWith(
        financialInfoData: newData,
        financialInfoExpanded: newExpanded,
        financialInfoLoading: newLoadingSet,
        financialInfoErrors: newErrorsMap,
      );
    } catch (e) {
      final newErrors = Map<String, String>.from(state.financialInfoErrors);
      newErrors[id] = e.toString();
      final newExpanded = Set<String>.from(state.financialInfoExpanded);
      newExpanded.remove(id);
      final newLoadingSet = Set<String>.from(state.financialInfoLoading);
      newLoadingSet.remove(id);
      state = state.copyWith(
        financialInfoErrors: newErrors,
        financialInfoExpanded: newExpanded,
        financialInfoLoading: newLoadingSet,
      );
    }
  }

  String getFinancialInfo(String id) {
    return state.financialInfoData[id] ?? '';
  }

  bool isFinancialInfoExpanded(String id) {
    return state.financialInfoExpanded.contains(id);
  }

  bool isFinancialInfoLoading(String id) {
    return state.financialInfoLoading.contains(id);
  }

  String? getFinancialInfoError(String id) {
    return state.financialInfoErrors[id];
  }

  // Helper methods
  static String getStatusText(String? status) {
    switch (status) {
      case '1':
        return 'Approved';
      case '2':
        return 'Pending';
      case '0':
        return 'Disapproved';
      case '4':
        return 'In Progress';
      default:
        return 'Unknown';
    }
  }

  static Color getStatusColor(String? status) {
    switch (status) {
      case '1':
        return AppTheme.successColor;
      case '2':
        return AppTheme.primaryColor;
      case '0':
        return AppTheme.errorColor;
      case '4':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  static String formatDate(String? dateString) {
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

  static String formatDownPayment(String? downPayment) {
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

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString == 'N/A' || dateString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getFilteredApplications(
    String status,
    String searchQuery,
  ) {
    final targetApplications = List<Map<String, dynamic>>.from(
      state.applicationsByStatus[status] ?? const <Map<String, dynamic>>[],
    );
    var filtered = targetApplications;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final applicant = (app['applicant']?.toString() ?? '').toLowerCase();
        final telephone = (app['telephone']?.toString() ?? '').toLowerCase();
        return applicant.contains(searchQuery) ||
            telephone.contains(searchQuery);
      }).toList();
    }

    filtered.sort((a, b) {
      final dateA = parseDate(a['date']?.toString());
      final dateB = parseDate(b['date']?.toString());

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  static List<FinancialInfoItem> extractFinancialInfoItems(String? data) {
    if (data == null || data.trim().isEmpty) {
      return const [];
    }

    print("Fin Data: ${data}");

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

    final items = <FinancialInfoItem>[];

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
      items.add(FinancialInfoItem(label: label, value: value));
    }

    // Add Username and Password first
    addItem(keys: ['username', 'user name', 'user'], label: 'Username');
    addItem(keys: ['password', 'pass'], label: 'Password');

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
        FinancialInfoItem(label: label, value: paymentEntry.value.trim()),
      );
    }

    addItem(
      keys: ['instalment start date', 'installment start date'],
      label: 'Installment Start Date',
    );

    addItem(keys: ['emi payment portal'], label: 'EMI Payment Portal');

    return items;
  }

  bool hasLoadedStatus(String status) {
    return state.applicationsByStatus.containsKey(status);
  }
}

final applicationListProvider =
    NotifierProvider<ApplicationListNotifier, ApplicationListState>(() {
      return ApplicationListNotifier();
    });
