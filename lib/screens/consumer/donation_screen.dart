import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/donation_model.dart';
import '../../models/charity_model.dart';
import '../../models/product_model.dart';
import '../../services/donation_service.dart';
import '../../services/product_service.dart';
import '../../utils/sample_charities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final DonationService _donationService = DonationService();
  final ProductService _productService = ProductService();
  
  List<DonationItem> _selectedItems = [];
  CharityModel? _selectedCharity;
  String _donationType = 'food'; // 'food', 'monetary', 'mixed'
  double _monetaryAmount = 0.0;
  String _selectedPaymentMethod = 'stripe';
  String _notes = '';
  String _pickupAddress = '';
  String _contactPhone = '';
  
  // Card details
  String _cardNumber = '';
  String _expiryDate = '';
  String _cvv = '';
  String _cardHolderName = '';
  
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Crops'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Make a Difference',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Donate your crops to help those in need',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step 1: Choose Donation Type
            _buildSectionHeader('Step 1: Choose Donation Type'),
            const SizedBox(height: 12),
            _buildDonationTypeSelection(),

            const SizedBox(height: 24),

            // Step 2: Select Products (conditional)
            if (_donationType == 'food' || _donationType == 'mixed') ...[
              _buildSectionHeader('Step 2: Select Products to Donate'),
              const SizedBox(height: 12),
              _buildProductSelection(),
              const SizedBox(height: 24),
            ],

            // Step 2/3: Monetary Donation (conditional)
            if (_donationType == 'monetary' || _donationType == 'mixed') ...[
              _buildSectionHeader(_donationType == 'monetary' ? 'Step 2: Monetary Donation' : 'Step 3: Monetary Donation'),
              const SizedBox(height: 12),
              _buildMonetaryDonation(),
              const SizedBox(height: 24),
            ],

            // Step 3/4: Choose Charity
            _buildSectionHeader(_donationType == 'monetary' ? 'Step 3: Choose Charity Organization' : 
                               _donationType == 'mixed' ? 'Step 4: Choose Charity Organization' : 
                               'Step 2: Choose Charity Organization'),
            const SizedBox(height: 12),
            _buildCharitySelection(),

            const SizedBox(height: 24),

            // Step 4/5: Pickup Details (only for food donations)
            if (_donationType == 'food' || _donationType == 'mixed') ...[
              _buildSectionHeader(_donationType == 'mixed' ? 'Step 5: Pickup Details' : 'Step 3: Pickup Details'),
              const SizedBox(height: 12),
              _buildPickupDetails(),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),

            // Step 4/5/6: Additional Notes
            _buildSectionHeader(_donationType == 'monetary' ? 'Step 4: Additional Notes' : 
                               _donationType == 'mixed' ? 'Step 6: Additional Notes' : 
                               'Step 4: Additional Notes'),
            const SizedBox(height: 12),
            _buildNotesSection(),

            const SizedBox(height: 24),

            // Summary
            if (_selectedCharity != null && 
                ((_donationType == 'food' && _selectedItems.isNotEmpty) ||
                 (_donationType == 'monetary' && _monetaryAmount > 0) ||
                 (_donationType == 'mixed' && (_selectedItems.isNotEmpty || _monetaryAmount > 0))))
              _buildDonationSummary(),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmitDonation() ? _submitDonation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Donation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDonationTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDonationTypeOption(
            'food',
            'Food Donation',
            'Donate fresh crops and produce',
            Icons.agriculture,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDonationTypeOption(
            'monetary',
            'Monetary Donation',
            'Donate money for maximum flexibility',
            Icons.attach_money,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildDonationTypeOption(
            'mixed',
            'Mixed Donation',
            'Donate both food and money',
            Icons.shopping_cart,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDonationTypeOption(String type, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _donationType == type;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _donationType = type;
            // Reset related fields when changing type
            if (type == 'monetary') {
              _selectedItems.clear();
            } else if (type == 'food') {
              _monetaryAmount = 0.0;
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: type,
                groupValue: _donationType,
                onChanged: (String? value) {
                  setState(() {
                    _donationType = value!;
                    // Reset related fields when changing type
                    if (value == 'monetary') {
                      _selectedItems.clear();
                    } else if (value == 'food') {
                      _monetaryAmount = 0.0;
                    }
                  });
                },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getAllAvailableProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Error loading products: ${snapshot.error}'),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No products available for donation'),
              ],
            ),
          );
        }

        return Column(
          children: products.map((product) => _buildProductCard(product)).toList(),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isSelected = _selectedItems.any((item) => item.productId == product.id);
      final selectedItem = _selectedItems.firstWhere(
        (item) => item.productId == product.id,
        orElse: () => DonationItem(
          productId: product.id,
          productName: product.productName,
          imageUrl: product.imageUrl,
          quantity: 0,
          estimatedValue: product.pricePerKg,
        ),
      );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.add(DonationItem(
                          productId: product.id,
                          productName: product.productName,
                          imageUrl: product.imageUrl,
                          quantity: 1.0,
                          estimatedValue: product.pricePerKg,
                        ));
                      } else {
                        _selectedItems.removeWhere((item) => item.productId == product.id);
                      }
                    });
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Available: ${product.quantity.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Est. Value: \$${product.pricePerKg.toStringAsFixed(2)}/kg',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity to donate:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: selectedItem.quantity > 0.1
                                    ? () {
                                        setState(() {
                                          final index = _selectedItems.indexWhere(
                                            (item) => item.productId == product.id,
                                          );
                                          if (index != -1) {
                                            final newQuantity = selectedItem.quantity - 0.1;
                                            if (newQuantity <= 0) {
                                              _selectedItems.removeAt(index);
                                            } else {
                                              _selectedItems[index] = selectedItem.copyWith(
                                                quantity: newQuantity,
                                              );
                                            }
                                          }
                                        });
                                      }
                                    : null,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${selectedItem.quantity.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: selectedItem.quantity < product.quantity
                                    ? () {
                                        setState(() {
                                          final index = _selectedItems.indexWhere(
                                            (item) => item.productId == product.id,
                                          );
                                          if (index != -1) {
                                            _selectedItems[index] = selectedItem.copyWith(
                                              quantity: selectedItem.quantity + 0.1,
                                            );
                                          }
                                        });
                                      }
                                    : null,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Available: ${product.quantity.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharitySelection() {
    return StreamBuilder<List<CharityModel>>(
      stream: _donationService.getActiveCharities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Error loading charities: ${snapshot.error}'),
              ],
            ),
          );
        }

        final charities = snapshot.data ?? [];

        if (charities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('No charities available at the moment'),
                const SizedBox(height: 16),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _addSampleCharities();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample charities added successfully!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding charities: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Sample Charities'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await _addAllCharities();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All 5 charities added successfully!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding charities: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Force Add All Charities'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          children: charities.map((charity) => _buildCharityCard(charity)).toList(),
        );
      },
    );
  }

  Widget _buildCharityCard(CharityModel charity) {
    final isSelected = _selectedCharity?.id == charity.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCharity = charity;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: charity.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          charity.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.volunteer_activism,
                              color: Colors.green,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.volunteer_activism,
                        color: Colors.green,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      charity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      charity.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            charity.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickupDetails() {
    return Column(
      children: [
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Pickup Address',
            hintText: 'Enter your address where crops can be picked up',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          onChanged: (value) => setState(() => _pickupAddress = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Contact Phone',
            hintText: 'Enter your phone number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => setState(() => _contactPhone = value),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Additional Notes',
        hintText: 'Any special instructions or notes for the charity...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
      onChanged: (value) => setState(() => _notes = value),
    );
  }

  Widget _buildDonationSummary() {
    final totalValue = _selectedItems.fold(0.0, (sum, item) => sum + item.totalValue);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donation Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedCharity != null) ...[
              Row(
                children: [
                  const Text('Charity: '),
                  Text(
                    _selectedCharity!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text('Items: ${_selectedItems.length}'),
            const SizedBox(height: 4),
            Text('Total Estimated Value: \$${totalValue.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Items:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            ..._selectedItems.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '• ${item.productName}: ${item.quantity.toStringAsFixed(1)} ${item.unit} (\$${item.totalValue.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )),
          ],
        ),
      ),
    );
  }

  bool _canSubmitDonation() {
    final hasValidDonation = 
      (_donationType == 'food' && _selectedItems.isNotEmpty) ||
      (_donationType == 'monetary' && _monetaryAmount > 0) ||
      (_donationType == 'mixed' && (_selectedItems.isNotEmpty || _monetaryAmount > 0));
    
    final hasRequiredInfo = _selectedCharity != null;
    
    // For food donations, pickup address and phone are required
    if (_donationType == 'food' || _donationType == 'mixed') {
      return hasValidDonation && hasRequiredInfo && 
             _pickupAddress.isNotEmpty && _contactPhone.isNotEmpty;
    }
    
    // For monetary donations, charity selection and basic card details presence are required
    if (_donationType == 'monetary') {
      return hasValidDonation && hasRequiredInfo &&
             _cardNumber.isNotEmpty && _expiryDate.isNotEmpty && 
             _cvv.isNotEmpty && _cardHolderName.isNotEmpty;
    }
    
    return hasValidDonation && hasRequiredInfo;
  }

  Future<void> _submitDonation() async {
    if (!_canSubmitDonation()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _donationType == 'monetary' || _donationType == 'mixed' 
                    ? 'Processing payment...' 
                    : 'Submitting donation...',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // For monetary donations, process payment first
      String paymentStatus = 'completed';
      if (_donationType == 'monetary' || _donationType == 'mixed') {
        paymentStatus = await _processPayment();
      }

      final donationId = await _donationService.createDonation(
        consumerId: authProvider.userProfile!.uid,
        consumerName: authProvider.userProfile!.displayName ?? 'Consumer',
        charityId: _selectedCharity!.id,
        charityName: _selectedCharity!.name,
        donationType: _donationType,
        items: _selectedItems,
        monetaryAmount: _monetaryAmount,
        paymentMethod: _donationType == 'monetary' || _donationType == 'mixed' ? _selectedPaymentMethod : null,
        paymentStatus: _donationType == 'monetary' || _donationType == 'mixed' ? paymentStatus : null,
        notes: _notes,
        pickupAddress: _pickupAddress,
        contactPhone: _contactPhone,
      );

      // For monetary donations, auto-complete the donation
      if (_donationType == 'monetary' || _donationType == 'mixed') {
        await _donationService.updateDonationStatus(donationId, 'completed');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _donationType == 'monetary' || _donationType == 'mixed' 
                    ? Icons.payment : Icons.check_circle, 
                color: Colors.green
              ),
              const SizedBox(width: 8),
              Text(
                _donationType == 'monetary' || _donationType == 'mixed' 
                    ? 'Payment Successful!' 
                    : 'Donation Submitted!'
              ),
            ],
          ),
          content: Text(
            _donationType == 'monetary' || _donationType == 'mixed'
                ? 'Your monetary donation has been processed successfully! The charity will receive the funds immediately.'
                : 'Your donation has been submitted successfully. The charity will contact you to arrange pickup.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('Failed to submit donation: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<String> _processPayment() async {
    try {
      // Validate card details before processing
      final validationError = _getCardValidationError();
      if (validationError != null) {
        throw Exception(validationError);
      }
      
      // Simulate Stripe payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would integrate with Stripe:
      // 1. Create Payment Intent
      // 2. Confirm Payment with card details
      // 3. Handle payment success/failure
      
      return 'completed';
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  String? _getCardValidationError() {
    print('Debug: Validating card number: "${_cardNumber}" (length: ${_cardNumber.length})');
    
    // Check card number
    if (_cardNumber.isEmpty) {
      return 'Please enter your card number';
    }
    if (_cardNumber.length != 16) {
      return 'Card number must be exactly 16 digits (current: ${_cardNumber.length} digits)';
    }
    
    // Check card holder name
    if (_cardHolderName.isEmpty) {
      return 'Please enter card holder name';
    }
    
    // Check expiry date
    if (_expiryDate.isEmpty) {
      return 'Please enter expiry date';
    }
    if (_expiryDate.length != 5 || !_expiryDate.contains('/')) {
      return 'Expiry date must be in MM/YY format';
    }
    
    // Validate expiry date format (MM/YY)
    final parts = _expiryDate.split('/');
    if (parts.length != 2) {
      return 'Invalid expiry date format';
    }
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) {
      return 'Invalid expiry date';
    }
    if (month < 1 || month > 12) {
      return 'Invalid month (must be 01-12)';
    }
    
    // Check if card is not expired
    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }
    
    // Check CVV
    if (_cvv.isEmpty) {
      return 'Please enter CVV';
    }
    if (_cvv.length < 3 || _cvv.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null; // No errors
  }

  bool _isValidCardDetails() {
    return _getCardValidationError() == null;
  }

  String _formatCardNumber(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Limit to exactly 16 digits
    final limitedDigits = digitsOnly.length > 16 ? digitsOnly.substring(0, 16) : digitsOnly;
    
    // Add spaces every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(limitedDigits[i]);
    }
    
    return buffer.toString();
  }

  String _formatExpiryDate(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 4 digits
    final limited = digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;
    
    // Add slash after 2 digits
    if (limited.length >= 2) {
      return '${limited.substring(0, 2)}/${limited.substring(2)}';
    }
    
    return limited;
  }

  // Example payment gateway integration methods (commented out for demo)
  /*
  Future<String> _processStripePayment() async {
    // Stripe integration
    // - Create payment intent
    // - Process card payment
    // - Return payment status
  }

  Future<String> _processPayPalPayment() async {
    // PayPal integration
    // - Create PayPal order
    // - Process payment
    // - Return payment status
  }

  Future<String> _processRazorpayPayment() async {
    // Razorpay integration
    // - Create Razorpay order
    // - Process payment
    // - Return payment status
  }

  Future<String> _processSquarePayment() async {
    // Square integration
    // - Create Square payment
    // - Process payment
    // - Return payment status
  }
  */

  Future<void> _addSampleCharities() async {
    await SampleCharities.addSampleCharities();
  }

  Future<void> _addAllCharities() async {
    final _firestore = FirebaseFirestore.instance;
    
    final charities = [
      CharityModel(
        id: 'charity_1',
        name: 'Food Bank of Hope',
        description: 'Providing nutritious meals and food assistance to families in need across the community.',
        imageUrl: 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400',
        address: '123 Hope Street, Community District',
        phone: '+1 (555) 123-4567',
        email: 'info@foodbankofhope.org',
        website: 'https://foodbankofhope.org',
        registrationNumber: 'FBH-2024-001',
        categories: ['food', 'community'],
        isActive: true,
        rating: 4.8,
        totalDonations: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      CharityModel(
        id: 'charity_2',
        name: 'Green Earth Foundation',
        description: 'Promoting sustainable agriculture and environmental conservation through community gardens and education.',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        address: '456 Green Valley Road, Eco District',
        phone: '+1 (555) 234-5678',
        email: 'contact@greenearth.org',
        website: 'https://greenearth.org',
        registrationNumber: 'GEF-2024-002',
        categories: ['environment', 'education', 'food'],
        isActive: true,
        rating: 4.6,
        totalDonations: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      CharityModel(
        id: 'charity_3',
        name: 'Community Care Center',
        description: 'Supporting vulnerable families with essential services including food assistance and emergency relief.',
        imageUrl: 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400',
        address: '789 Care Avenue, Support District',
        phone: '+1 (555) 345-6789',
        email: 'help@communitycare.org',
        website: 'https://communitycare.org',
        registrationNumber: 'CCC-2024-003',
        categories: ['community', 'health', 'food'],
        isActive: true,
        rating: 4.9,
        totalDonations: 203,
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
      ),
      CharityModel(
        id: 'charity_4',
        name: 'Youth Development Alliance',
        description: 'Empowering young people through education, mentorship, and access to healthy food programs.',
        imageUrl: 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400',
        address: '321 Youth Boulevard, Education District',
        phone: '+1 (555) 456-7890',
        email: 'youth@alliance.org',
        website: 'https://youthalliance.org',
        registrationNumber: 'YDA-2024-004',
        categories: ['education', 'youth', 'community'],
        isActive: true,
        rating: 4.7,
        totalDonations: 134,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      CharityModel(
        id: 'charity_5',
        name: 'Harvest for All',
        description: 'Connecting local farmers with food assistance programs to ensure no one goes hungry in our community.',
        imageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400',
        address: '654 Harvest Lane, Farm District',
        phone: '+1 (555) 567-8901',
        email: 'harvest@forall.org',
        website: 'https://harvestforall.org',
        registrationNumber: 'HFA-2024-005',
        categories: ['food', 'agriculture', 'community'],
        isActive: true,
        rating: 4.5,
        totalDonations: 97,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];

    try {
      for (final charity in charities) {
        await _firestore.collection('charities').doc(charity.id).set(charity.toMap());
        print('Added charity: ${charity.name}');
      }
      print('All 5 charities added successfully!');
    } catch (e) {
      print('Error adding charities: $e');
      rethrow;
    }
  }

  Widget _buildMonetaryDonation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Monetary Donation Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Amount Input
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Donation Amount',
              hintText: 'Enter amount in USD',
              prefixIcon: const Icon(Icons.attach_money),
              suffixText: 'USD',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _monetaryAmount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Quick Amount Buttons
          Text(
            'Quick Amounts:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 25, 50, 100, 250, 500].map((amount) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _monetaryAmount = amount.toDouble();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _monetaryAmount == amount ? Colors.blue.shade600 : Colors.blue.shade100,
                  foregroundColor: _monetaryAmount == amount ? Colors.white : Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('\$$amount'),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method - Stripe Only
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stripe Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Secure payment processing',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card Details
          Text(
            'Card Details:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19, // 16 digits + 3 spaces = 19 characters
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
            ],
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              counterText: '', // Hide the character counter
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: (value) {
              // Format card number with spaces (e.g., 1234 5678 9012 3456)
              final formatted = _formatCardNumber(value);
              if (formatted != value) {
                _cardNumberController.value = _cardNumberController.value.copyWith(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              setState(() {
                // Store only the digits (no spaces)
                _cardNumber = formatted.replaceAll(' ', '');
                print('Debug: Card number stored: "${_cardNumber}" (length: ${_cardNumber.length})');
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Card Holder Name
          TextFormField(
            controller: _cardNameController,
            decoration: InputDecoration(
              labelText: 'Card Holder Name',
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _cardHolderName = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Expiry Date and CVV
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  maxLength: 5, // MM/YY format
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4), // Only 4 digits, slash added automatically
                  ],
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    counterText: '', // Hide the character counter
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    // Format expiry date (e.g., MM/YY)
                    final formatted = _formatExpiryDate(value);
                    if (formatted != value) {
                      _expiryController.value = _expiryController.value.copyWith(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    setState(() {
                      _expiryDate = formatted;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4, // CVV can be 3 or 4 digits
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    counterText: '', // Hide the character counter
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _cvv = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Donation Impact Info
          if (_monetaryAmount > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With \$${_monetaryAmount.toStringAsFixed(2)}, this charity can provide approximately ${(_monetaryAmount / 3).round()} meals to families in need.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}

extension on DonationItem {
  DonationItem copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    double? quantity,
    double? estimatedValue,
    String? unit,
    String? notes,
  }) {
    return DonationItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }
}
