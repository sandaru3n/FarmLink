import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../services/payment_service.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider.dart';
import 'payment_success_screen.dart';
import '../farmer/map_location_picker_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _zipController = TextEditingController();
  final _distributorLocationController = TextEditingController();

  bool _isProcessing = false;
  bool _saveCard = true;
  String _selectedCountry = 'United States';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Location data
  double? _shippingLatitude;
  double? _shippingLongitude;

  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'India',
    'Sri Lanka',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _zipController.dispose();
    _distributorLocationController.dispose();
    super.dispose();
  }

  void _formatCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digits[i];
    }
    if (formatted != _cardNumberController.text) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _formatExpiryDate(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) {
        formatted += '/';
      }
      formatted += digits[i];
    }
    if (formatted != _expiryController.text) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  bool _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length == 16;
  }

  bool _validateExpiry(String? value) {
    if (value == null || value.isEmpty) return false;
    final parts = value.split('/');
    if (parts.length != 2) return false;
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }
    
    return true;
  }

  bool _validateCvv(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 3 && value.length <= 4;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get distributor location from the form
      final distributorLocation = _distributorLocationController.text.trim();
      
      // Use simple payment processing with location coordinates
      final paymentService = PaymentService();
      final success = await paymentService.processSimplePayment(
        widget.order,
        distributorLocation: distributorLocation.isNotEmpty ? distributorLocation : null,
        distributorLatitude: _shippingLatitude,
        distributorLongitude: _shippingLongitude,
      );
      
      if (success) {
        // Show success message before navigating
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment processed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to success screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(order: widget.order),
            ),
          );
        }
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pay \$${widget.order.finalPrice.toStringAsFixed(2)} using',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Information Section
                _buildSectionTitle('Card Information'),
                const SizedBox(height: 16),
                
                                 // Card Number Field
                 _buildCardNumberField(),
                 const SizedBox(height: 16),
                 
                 // Expiry and CVV Row
                 Row(
                   children: [
                     Expanded(
                       flex: 2,
                       child: _buildExpiryField(),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildCvvField(),
                     ),
                   ],
                 ),
                 const SizedBox(height: 24),
                 
                 // Distributor Location Section
                 _buildSectionTitle('Shipping Address'),
                 const SizedBox(height: 16),
                 
                 // Distributor Location Field
                 _buildDistributorLocationField(),
                 const SizedBox(height: 24),
                 
                 // Billing Address Section
                 _buildSectionTitle('Billing Address'),
                 const SizedBox(height: 16),
                 
                 // Country Dropdown
                 _buildCountryDropdown(),
                 const SizedBox(height: 16),
                 
                 // ZIP Code Field
                 _buildZipField(),
                const SizedBox(height: 24),
                
                // Save Card Option
                _buildSaveCardOption(),
                const SizedBox(height: 32),
                
                // Payment Button
                _buildPaymentButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCardNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _cardNumberController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(19),
        ],
        onChanged: _formatCardNumber,
        validator: (value) {
          if (!_validateCardNumber(value)) {
            return 'Please enter a valid card number';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Card number',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCardIcon('visa'),
                const SizedBox(width: 8),
                _buildCardIcon('mastercard'),
                const SizedBox(width: 8),
                _buildCardIcon('amex'),
                const SizedBox(width: 8),
                _buildCardIcon('discover'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardIcon(String type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case 'visa':
        iconData = Icons.credit_card;
        color = Colors.blue[700]!;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.orange[700]!;
        break;
      case 'amex':
        iconData = Icons.credit_card;
        color = Colors.green[700]!;
        break;
      case 'discover':
        iconData = Icons.credit_card;
        color = Colors.red[700]!;
        break;
      default:
        iconData = Icons.credit_card;
        color = Colors.grey;
    }
    
    return Icon(iconData, size: 20, color: color);
  }

  Widget _buildExpiryField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _expiryController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        onChanged: _formatExpiryDate,
        validator: (value) {
          if (!_validateExpiry(value)) {
            return 'Invalid expiry date';
          }
          return null;
        },
        decoration: const InputDecoration(
          hintText: 'MM/YY',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCvvField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _cvvController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        validator: (value) {
          if (!_validateCvv(value)) {
            return 'Invalid CVV';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'CVC',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CVC/CVV'),
                  content: const Text(
                    'The 3 or 4 digit security code on the back of your card.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCountry,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: _countries.map((String country) {
          return DropdownMenuItem<String>(
            value: country,
            child: Text(country),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue!;
          });
        },
      ),
    );
  }

  Future<void> _openShippingMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLatitude: _shippingLatitude,
          initialLongitude: _shippingLongitude,
          initialAddress: _distributorLocationController.text.isNotEmpty 
              ? _distributorLocationController.text 
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _shippingLatitude = result['latitude'];
        _shippingLongitude = result['longitude'];
        _distributorLocationController.text = result['address'];
      });
    }
  }

  Widget _buildDistributorLocationField() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Delivery Address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openShippingMapPicker,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Select on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distributorLocationController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tap "Select on Map" to choose your delivery location',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _shippingLatitude != null && _shippingLongitude != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select your delivery location using the map';
                }
                return null;
              },
            ),
            if (_shippingLatitude != null && _shippingLongitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Location confirmed • ${_shippingLatitude!.toStringAsFixed(6)}, ${_shippingLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZipField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _zipController,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          hintText: 'ZIP',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSaveCardOption() {
    return Row(
      children: [
        Checkbox(
          value: _saveCard,
          onChanged: (value) {
            setState(() {
              _saveCard = value!;
            });
          },
          activeColor: Colors.blue[600],
        ),
        const Expanded(
          child: Text(
            'Save card for future FarmLink payments',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay \$${widget.order.finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
