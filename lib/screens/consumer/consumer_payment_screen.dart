import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/consumer_order_model.dart';
import '../../services/consumer_order_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'consumer_payment_success_screen.dart';

class ConsumerPaymentScreen extends StatefulWidget {
  final ConsumerOrderModel order;

  const ConsumerPaymentScreen({super.key, required this.order});

  @override
  State<ConsumerPaymentScreen> createState() => _ConsumerPaymentScreenState();
}

class _ConsumerPaymentScreenState extends State<ConsumerPaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _zipController = TextEditingController();
  final _consumerLocationController = TextEditingController();

  bool _isProcessing = false;
  bool _saveCard = true;
  String _selectedCountry = 'India';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _countries = [
    'India',
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
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
    _consumerLocationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get consumer location from the form
      final consumerLocation = _consumerLocationController.text.trim();
      
      // Use consumer order service for payment processing
      final consumerOrderService = ConsumerOrderService();
      final success = await consumerOrderService.processConsumerOrderPayment(
        widget.order,
        consumerLocation: consumerLocation.isNotEmpty ? consumerLocation : null,
      );
      
      if (success) {
        // Clear the cart after successful payment
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        
        if (authProvider.userProfile != null) {
          await cartProvider.clearCart(authProvider.userProfile!.uid);
        }

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
              builder: (context) => ConsumerPaymentSuccessScreen(order: widget.order),
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
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item.quantity.toStringAsFixed(1)} kg',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Subtotal:'),
                            ),
                            Text(
                              '₹${widget.order.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Tax (18% GST):'),
                            ),
                            Text(
                              '₹${widget.order.tax.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '₹${widget.order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery Location
                const Text(
                  'Delivery Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _consumerLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'Enter your delivery address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your delivery address';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Payment Information
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Card Number
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (value) {
                    if (value == null || value.length < 16) {
                      return 'Please enter a valid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cardholder Name
                TextFormField(
                  controller: _cardholderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    hintText: 'John Doe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter cardholder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiry and CVV Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.length < 4) {
                            return 'Please enter expiry date';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.length < 3) {
                            return 'Please enter CVV';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Country Selection
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
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
                const SizedBox(height: 16),

                // ZIP Code
                TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code',
                    hintText: '12345',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter ZIP code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Save Card Checkbox
                CheckboxListTile(
                  title: const Text('Save card for future payments'),
                  value: _saveCard,
                  onChanged: (bool? value) {
                    setState(() {
                      _saveCard = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing Payment...'),
                            ],
                          )
                        : Text(
                            'Pay ₹${widget.order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is secure and encrypted',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 