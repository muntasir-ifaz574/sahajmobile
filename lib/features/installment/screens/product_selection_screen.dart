import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/providers/application_provider.dart';

import '../../../core/theme/app_theme.dart';

class ProductSelectionScreen extends ConsumerStatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  String? selectedBrand;
  String? selectedModel;
  List<String> brands = [];
  List<Map<String, String>> modelOptions = [];

  bool _loadingBrands = false;
  bool _loadingModels = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
    // Load existing product from provider after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProduct();
    });
  }

  void _loadExistingProduct() {
    final existingProduct = ref.read(selectedProductProvider);
    if (existingProduct != null && mounted) {
      setState(() {
        selectedBrand = existingProduct.brand;
      });
      // Load models for the existing brand
      if (existingProduct.brand.isNotEmpty) {
        _loadModels(existingProduct.brand).then((_) {
          if (mounted && existingProduct.model.isNotEmpty) {
            // Find and select the matching model
            final modelMatch = modelOptions.firstWhere(
              (m) => m['description'] == existingProduct.model,
              orElse: () => {},
            );
            if (modelMatch.isNotEmpty) {
              final desc = modelMatch['description'] ?? '';
              final price = modelMatch['price'] ?? existingProduct.price.toString();
              setState(() {
                selectedModel = '$desc|$price';
              });
            }
          }
        });
      }
    }
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _error = null;
    });
    try {
      final shopId = await StorageService.getShopId();
      if (shopId == null) throw Exception('Shop id not found');
      final fetched = await ApiService.getBrands(shopId: shopId);
      setState(() {
        brands = fetched;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingBrands = false;
      });
    }
  }

  Future<void> _loadModels(String brand) async {
    setState(() {
      _loadingModels = true;
      _error = null;
    });
    try {
      final fetched = await ApiService.getModels(brand: brand);
      setState(() {
        modelOptions = fetched;
        selectedModel = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingModels = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Mobile Model',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Installment Product Section
            _buildInstallmentProductSection(),

            const SizedBox(height: 24),

            // Product Selection Form
            _buildProductSelectionForm(),

            const SizedBox(height: 40),

            // Next Button
            if (selectedBrand != null && selectedModel != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Parse selected model composite value: description|price
                    final parts = (selectedModel ?? '').split('|');
                    final modelName = parts.isNotEmpty ? parts[0] : '';
                    final price = parts.length > 1 ? parts[1] : '';
                    context.go(
                      '/installment/payment-terms',
                      extra: {
                        'brand': selectedBrand,
                        'model': modelName,
                        'price': price,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentProductSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Installment Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedBrand != null && selectedModel != null
                ? '1 Product Selected'
                : 'No Product Selected',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Dropdown
        DropdownButtonFormField<String>(
          value: selectedBrand,
          decoration: InputDecoration(
            labelText: 'Brand',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: brands.map((brand) {
            return DropdownMenuItem(value: brand, child: Text(brand));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedBrand = value;
              selectedModel = null;
              modelOptions = [];
            });
            if (value != null) {
              _loadModels(value);
            }
          },
        ),

        const SizedBox(height: 16),

        // Model Dropdown
        DropdownButtonFormField<String>(
          value: selectedModel,
          decoration: InputDecoration(
            labelText: 'Model',
            hintText: 'Select model',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: selectedBrand != null
              ? modelOptions.map((m) {
                  final desc = m['description'] ?? '';
                  final price = m['price'] ?? '';
                  final value = '$desc|$price';
                  return DropdownMenuItem(value: value, child: Text(desc));
                }).toList()
              : [],
          onChanged: selectedBrand != null
              ? (value) {
                  setState(() {
                    selectedModel = value;
                  });
                }
              : null,
        ),

        if (_loadingBrands || _loadingModels)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
