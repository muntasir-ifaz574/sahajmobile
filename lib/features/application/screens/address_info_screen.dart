import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/division_model.dart';
import '../../../shared/models/district_model.dart';
import '../../../shared/models/thana_model.dart';
import '../../../shared/models/union_model.dart';
import '../../../shared/providers/application_provider.dart';

class AddressInfoScreen extends ConsumerStatefulWidget {
  const AddressInfoScreen({super.key});

  @override
  ConsumerState<AddressInfoScreen> createState() => _AddressInfoScreenState();
}

class _AddressInfoScreenState extends ConsumerState<AddressInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressDetailsController = TextEditingController();
  final _permanentAddressDetailsController = TextEditingController();

  // Permanent address location state
  List<Division> _permanentDivisions = [];
  List<District> _permanentDistricts = [];
  List<Thana> _permanentThanas = [];
  List<UnionModel> _permanentUnions = [];
  Division? _selectedPermanentDivision;
  District? _selectedPermanentDistrict;
  Thana? _selectedPermanentThana;
  UnionModel? _selectedPermanentUnion;
  bool _isLoadingPermanentDivisions = false;
  bool _isLoadingPermanentDistricts = false;
  bool _isLoadingPermanentThanas = false;
  bool _isLoadingPermanentUnions = false;
  String? _permanentDivisionError;
  String? _permanentDistrictError;
  String? _permanentThanaError;
  String? _permanentUnionError;
  bool _isSameAsCurrentAddress = false;

  @override
  void initState() {
    super.initState();
    // Delay the data loading to avoid modifying providers during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      _fetchDivisions();
      _fetchPermanentDivisions();
    });
  }

  @override
  void dispose() {
    _addressDetailsController.dispose();
    _permanentAddressDetailsController.dispose();
    super.dispose();
  }

  void _loadExistingData() async {
    final addressInfo = ref.read(addressInfoProvider);
    if (addressInfo != null) {
      _addressDetailsController.text = addressInfo.addressDetails;
      _permanentAddressDetailsController.text =
          addressInfo.permanentAddressDetails;

      // Check if permanent address is same as current address
      final isSame =
          addressInfo.division == addressInfo.permanentDivision &&
          addressInfo.district == addressInfo.permanentDistrict &&
          addressInfo.upazila == addressInfo.permanentUpazila &&
          addressInfo.addressDetails == addressInfo.permanentAddressDetails;

      setState(() {
        _isSameAsCurrentAddress = isSame;
      });

      // Load permanent address selections if IDs exist and not same as current
      if (!isSame && addressInfo.permanentDivision.isNotEmpty) {
        // Fetch divisions first, then find and select the matching one
        await _fetchPermanentDivisions();
        if (mounted && _permanentDivisions.isNotEmpty) {
          final permanentDiv = _permanentDivisions.firstWhere(
            (d) => d.id == addressInfo.permanentDivision,
            orElse: () => _permanentDivisions.first,
          );
          setState(() {
            _selectedPermanentDivision = permanentDiv;
          });
          await _fetchPermanentDistricts(permanentDiv.id);

          if (mounted &&
              addressInfo.permanentDistrict.isNotEmpty &&
              _permanentDistricts.isNotEmpty) {
            final permanentDist = _permanentDistricts.firstWhere(
              (d) => d.id == addressInfo.permanentDistrict,
              orElse: () => _permanentDistricts.first,
            );
            setState(() {
              _selectedPermanentDistrict = permanentDist;
            });
            await _fetchPermanentThanas(permanentDist.id);

            if (mounted &&
                addressInfo.permanentUpazila.isNotEmpty &&
                _permanentThanas.isNotEmpty) {
              final permanentThana = _permanentThanas.firstWhere(
                (t) => t.id == addressInfo.permanentUpazila,
                orElse: () => _permanentThanas.first,
              );
              setState(() {
                _selectedPermanentThana = permanentThana;
              });
              await _fetchPermanentUnions(permanentThana.id);

              if (mounted &&
                  addressInfo.permanentUnion.isNotEmpty &&
                  _permanentUnions.isNotEmpty) {
                final permanentUnion = _permanentUnions.firstWhere(
                  (u) => u.id == addressInfo.permanentUnion,
                  orElse: () => _permanentUnions.first,
                );
                setState(() {
                  _selectedPermanentUnion = permanentUnion;
                });
              }
            }
          }
        }
      }
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

  Future<void> _fetchUnions(String upazillaId) async {
    ref.read(locationDataProvider.notifier).setLoadingUnions(true);
    try {
      final unions = await ApiService.getUnions(upazillaId: upazillaId);
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setUnions(unions);
    } catch (e) {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setUnionError(e.toString());
    } finally {
      if (!mounted) return;
      ref.read(locationDataProvider.notifier).setLoadingUnions(false);
    }
  }

  // Permanent address fetch methods
  Future<void> _fetchPermanentDivisions() async {
    setState(() {
      _isLoadingPermanentDivisions = true;
      _permanentDivisionError = null;
    });
    try {
      final divisions = await ApiService.getDivisions();
      if (!mounted) return;
      setState(() {
        _permanentDivisions = divisions;
        _isLoadingPermanentDivisions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permanentDivisionError = e.toString();
        _isLoadingPermanentDivisions = false;
      });
    }
  }

  Future<void> _fetchPermanentDistricts(String divisionId) async {
    setState(() {
      _isLoadingPermanentDistricts = true;
      _permanentDistrictError = null;
    });
    try {
      final districts = await ApiService.getDistricts(
        datadivisionId: divisionId,
      );
      if (!mounted) return;
      setState(() {
        _permanentDistricts = districts;
        _isLoadingPermanentDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permanentDistrictError = e.toString();
        _isLoadingPermanentDistricts = false;
      });
    }
  }

  Future<void> _fetchPermanentThanas(String districtId) async {
    setState(() {
      _isLoadingPermanentThanas = true;
      _permanentThanaError = null;
    });
    try {
      final thanas = await ApiService.getThanas(districtId: districtId);
      if (!mounted) return;
      setState(() {
        _permanentThanas = thanas;
        _isLoadingPermanentThanas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permanentThanaError = e.toString();
        _isLoadingPermanentThanas = false;
      });
    }
  }

  Future<void> _fetchPermanentUnions(String upazillaId) async {
    setState(() {
      _isLoadingPermanentUnions = true;
      _permanentUnionError = null;
    });
    try {
      final unions = await ApiService.getUnions(upazillaId: upazillaId);
      if (!mounted) return;
      setState(() {
        _permanentUnions = unions;
        _isLoadingPermanentUnions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permanentUnionError = e.toString();
        _isLoadingPermanentUnions = false;
      });
    }
  }

  void _saveAddressInfo() {
    final locationState = ref.read(locationDataProvider);
    if (locationState.selectedDivision == null ||
        locationState.selectedDistrict == null ||
        locationState.selectedThana == null) {
      return;
    }

    // If same as current address, use current address values
    String permanentDivision;
    String permanentDistrict;
    String permanentUpazila;
    String permanentUnion;
    String permanentAddressDetails;

    if (_isSameAsCurrentAddress) {
      permanentDivision = locationState.selectedDivision!.id;
      permanentDistrict = locationState.selectedDistrict!.id;
      permanentUpazila = locationState.selectedThana!.id;
      permanentUnion = locationState.selectedUnion?.id ?? '';
      permanentAddressDetails = _addressDetailsController.text.trim();
    } else {
      // Validate permanent address fields
      if (_selectedPermanentDivision == null ||
          _selectedPermanentDistrict == null ||
          _selectedPermanentThana == null ||
          _selectedPermanentUnion == null) {
        return;
      }
      permanentDivision = _selectedPermanentDivision!.id;
      permanentDistrict = _selectedPermanentDistrict!.id;
      permanentUpazila = _selectedPermanentThana!.id;
      permanentUnion = _selectedPermanentUnion!.id;
      permanentAddressDetails = _permanentAddressDetailsController.text.trim();
    }

    final addressInfo = AddressInfo(
      division: locationState.selectedDivision!.id,
      district: locationState.selectedDistrict!.id,
      upazila: locationState.selectedThana!.id,
      addressDetails: _addressDetailsController.text.trim(),
      permanentDivision: permanentDivision,
      permanentDistrict: permanentDistrict,
      permanentUpazila: permanentUpazila,
      permanentUnion: permanentUnion,
      permanentAddressDetails: permanentAddressDetails,
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
                'Current Residential Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
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
                value: locationState.selectedDivision != null &&
                        locationState.divisions
                            .any((d) => d.id == locationState.selectedDivision!.id)
                    ? locationState.selectedDivision!.id
                    : null,
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
                value: locationState.selectedDistrict != null &&
                        locationState.districts
                            .any((d) => d.id == locationState.selectedDistrict!.id)
                    ? locationState.selectedDistrict!.id
                    : null,
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
                value: locationState.selectedThana != null &&
                        locationState.thanas
                            .any((t) => t.id == locationState.selectedThana!.id)
                    ? locationState.selectedThana!.id
                    : null,
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
                        _fetchUnions(selected.id);
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

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Union',
                  hintText: 'Please select',
                ),
                isExpanded: true,
                value: locationState.selectedUnion != null &&
                        locationState.unions
                            .any((u) => u.id == locationState.selectedUnion!.id)
                    ? locationState.selectedUnion!.id
                    : null,
                items: locationState.unions
                    .map(
                      (u) => DropdownMenuItem<String>(
                        value: u.id,
                        child: Text(u.name),
                      ),
                    )
                    .toList(),
                onChanged:
                    (locationState.isLoadingUnions ||
                        locationState.unions.isEmpty)
                    ? null
                    : (value) {
                        final selected = locationState.unions.firstWhere(
                          (u) => u.id == value,
                        );
                        ref
                            .read(locationDataProvider.notifier)
                            .setSelectedUnion(selected);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a union';
                  }
                  return null;
                },
              ),
              if (locationState.isLoadingUnions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (locationState.unionError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    locationState.unionError!,
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
              // Permanent Address Section
              const Divider(height: 40),
              const Text(
                'Permanent Residential Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your permanent residential address',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Same as current address option
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Same as current address',
                  hintText: 'Please select',
                ),
                isExpanded: true,
                value: _isSameAsCurrentAddress ? 'Yes' : 'No',
                items: const [
                  DropdownMenuItem(value: 'No', child: Text('No')),
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isSameAsCurrentAddress = value == 'Yes';
                    if (_isSameAsCurrentAddress) {
                      // Clear permanent address selections when same as current
                      _selectedPermanentDivision = null;
                      _selectedPermanentDistrict = null;
                      _selectedPermanentThana = null;
                      _selectedPermanentUnion = null;
                      _permanentDistricts = [];
                      _permanentThanas = [];
                      _permanentUnions = [];
                      _permanentAddressDetailsController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an option';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Show permanent address fields only if "No" is selected
              if (!_isSameAsCurrentAddress) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Division',
                    hintText: 'Please select',
                  ),
                  isExpanded: true,
                  value: _selectedPermanentDivision != null &&
                          _permanentDivisions
                              .any((d) => d.id == _selectedPermanentDivision!.id)
                      ? _selectedPermanentDivision!.id
                      : null,
                  items: _permanentDivisions
                      .map(
                        (d) => DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingPermanentDivisions
                      ? null
                      : (value) {
                          final selected = _permanentDivisions.firstWhere(
                            (d) => d.id == value,
                          );
                          setState(() {
                            _selectedPermanentDivision = selected;
                            _selectedPermanentDistrict = null;
                            _selectedPermanentThana = null;
                            _selectedPermanentUnion = null;
                            _permanentDistricts = [];
                            _permanentThanas = [];
                            _permanentUnions = [];
                          });
                          _fetchPermanentDistricts(selected.id);
                        },
                  validator: (value) {
                    if (!_isSameAsCurrentAddress) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a division';
                      }
                    }
                    return null;
                  },
                ),
                if (_isLoadingPermanentDivisions)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_permanentDivisionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _permanentDivisionError!,
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
                  value: _selectedPermanentDistrict != null &&
                          _permanentDistricts
                              .any((d) => d.id == _selectedPermanentDistrict!.id)
                      ? _selectedPermanentDistrict!.id
                      : null,
                  items: _permanentDistricts
                      .map(
                        (d) => DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (_isLoadingPermanentDistricts ||
                          _permanentDistricts.isEmpty)
                      ? null
                      : (value) {
                          final selected = _permanentDistricts.firstWhere(
                            (d) => d.id == value,
                          );
                          setState(() {
                            _selectedPermanentDistrict = selected;
                            _selectedPermanentThana = null;
                            _selectedPermanentUnion = null;
                            _permanentThanas = [];
                            _permanentUnions = [];
                          });
                          _fetchPermanentThanas(selected.id);
                        },
                  validator: (value) {
                    if (!_isSameAsCurrentAddress) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a district';
                      }
                    }
                    return null;
                  },
                ),
                if (_isLoadingPermanentDistricts)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_permanentDistrictError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _permanentDistrictError!,
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
                  value: _selectedPermanentThana != null &&
                          _permanentThanas
                              .any((t) => t.id == _selectedPermanentThana!.id)
                      ? _selectedPermanentThana!.id
                      : null,
                  items: _permanentThanas
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t.id,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (_isLoadingPermanentThanas || _permanentThanas.isEmpty)
                      ? null
                      : (value) {
                          final selected = _permanentThanas.firstWhere(
                            (t) => t.id == value,
                          );
                          setState(() {
                            _selectedPermanentThana = selected;
                            _selectedPermanentUnion = null;
                            _permanentUnions = [];
                          });
                          _fetchPermanentUnions(selected.id);
                        },
                  validator: (value) {
                    if (!_isSameAsCurrentAddress) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a thana/upazila';
                      }
                    }
                    return null;
                  },
                ),
                if (_isLoadingPermanentThanas)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_permanentThanaError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _permanentThanaError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Union',
                    hintText: 'Please select',
                  ),
                  isExpanded: true,
                  value: _selectedPermanentUnion != null &&
                          _permanentUnions
                              .any((u) => u.id == _selectedPermanentUnion!.id)
                      ? _selectedPermanentUnion!.id
                      : null,
                  items: _permanentUnions
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(u.name),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (_isLoadingPermanentUnions || _permanentUnions.isEmpty)
                      ? null
                      : (value) {
                          final selected = _permanentUnions.firstWhere(
                            (u) => u.id == value,
                          );
                          setState(() {
                            _selectedPermanentUnion = selected;
                          });
                        },
                  validator: (value) {
                    if (!_isSameAsCurrentAddress) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a union';
                      }
                    }
                    return null;
                  },
                ),
                if (_isLoadingPermanentUnions)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_permanentUnionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _permanentUnionError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _permanentAddressDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'Permanent Address Details',
                    hintText: 'Enter your permanent address',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (!_isSameAsCurrentAddress) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter permanent address details';
                      }
                    }
                    return null;
                  },
                ),
              ],
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
