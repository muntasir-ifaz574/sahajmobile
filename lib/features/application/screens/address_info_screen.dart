import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/providers/application_provider.dart';

class AddressInfoScreen extends ConsumerStatefulWidget {
  const AddressInfoScreen({super.key});

  @override
  ConsumerState<AddressInfoScreen> createState() => _AddressInfoScreenState();
}

class _AddressInfoScreenState extends ConsumerState<AddressInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Delay the data loading to avoid modifying providers during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      _fetchDivisions();
    });
  }

  @override
  void dispose() {
    _addressDetailsController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final addressInfo = ref.read(addressInfoProvider);
    if (addressInfo != null) {
      _addressDetailsController.text = addressInfo.addressDetails;
    }
  }

  Future<void> _fetchDivisions() async {
    ref.read(locationDataProvider.notifier).setLoadingDivisions(true);
    try {
      final divisions = await ApiService.getDivisions();
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setDivisions(divisions);
    } catch (e) {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setDivisionError(e.toString());
    } finally {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setLoadingDivisions(false);
    }
  }

  Future<void> _fetchDistricts(String divisionId) async {
    ref.read(locationDataProvider.notifier).setLoadingDistricts(true);
    try {
      final districts = await ApiService.getDistricts(
        datadivisionId: divisionId,
      );
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setDistricts(districts);
    } catch (e) {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setDistrictError(e.toString());
    } finally {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setLoadingDistricts(false);
    }
  }

  Future<void> _fetchThanas(String districtId) async {
    ref.read(locationDataProvider.notifier).setLoadingThanas(true);
    try {
      final thanas = await ApiService.getThanas(districtId: districtId);
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setThanas(thanas);
    } catch (e) {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setThanaError(e.toString());
    } finally {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setLoadingThanas(false);
    }
  }

  void _saveAddressInfo() {
    final locationState = ref.read(locationDataProvider);
    if (locationState.selectedDivision == null ||
        locationState.selectedDistrict == null ||
        locationState.selectedThana == null) {
      return;
    }

    final addressInfo = AddressInfo(
      division: locationState.selectedDivision!.name,
      district: locationState.selectedDistrict!.name,
      upazila: locationState.selectedThana!.name,
      addressDetails: _addressDetailsController.text.trim(),
    );

    ref.read(applicationDataProvider.notifier).setAddressInfo(addressInfo);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Address Information',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/verification/confirm-info'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter your current residential address',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Division',
                  hintText: 'Please select',
                ),
                isExpanded: true,
                value: locationState.selectedDivision?.id,
                items: locationState.divisions
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.name),
                      ),
                    )
                    .toList(),
                onChanged: locationState.isLoadingDivisions
                    ? null
                    : (value) {
                        final selected = locationState.divisions.firstWhere(
                          (d) => d.id == value,
                        );
                        ref
                            .read(locationDataProvider.notifier)
                            .setSelectedDivision(selected);
                        _fetchDistricts(selected.id);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a division';
                  }
                  return null;
                },
              ),
              if (locationState.isLoadingDivisions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (locationState.divisionError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    locationState.divisionError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'District',
                  hintText: 'Please select',
                ),
                isExpanded: true,
                value: locationState.selectedDistrict?.id,
                items: locationState.districts
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.name),
                      ),
                    )
                    .toList(),
                onChanged:
                    (locationState.isLoadingDistricts ||
                        locationState.districts.isEmpty)
                    ? null
                    : (value) {
                        final selected = locationState.districts.firstWhere(
                          (d) => d.id == value,
                        );
                        ref
                            .read(locationDataProvider.notifier)
                            .setSelectedDistrict(selected);
                        _fetchThanas(selected.id);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a district';
                  }
                  return null;
                },
              ),
              if (locationState.isLoadingDistricts)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (locationState.districtError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    locationState.districtError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Upazila/Thana',
                  hintText: 'Please select',
                ),
                isExpanded: true,
                value: locationState.selectedThana?.id,
                items: locationState.thanas
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name),
                      ),
                    )
                    .toList(),
                onChanged:
                    (locationState.isLoadingThanas ||
                        locationState.thanas.isEmpty)
                    ? null
                    : (value) {
                        final selected = locationState.thanas.firstWhere(
                          (t) => t.id == value,
                        );
                        ref
                            .read(locationDataProvider.notifier)
                            .setSelectedThana(selected);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a thana/upazila';
                  }
                  return null;
                },
              ),
              if (locationState.isLoadingThanas)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (locationState.thanaError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    locationState.thanaError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Address Details',
                  hintText: 'Enter your address',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveAddressInfo();
                      context.go('/application/job-income');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
