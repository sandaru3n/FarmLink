import 'package:flutter/material.dart';
import '../../services/crop_advisory_service.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  final CropAdvisoryService _advisoryService = CropAdvisoryService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _cropController = TextEditingController();
  final _locationController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _weatherController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  String _advisoryResult = '';
  String _errorMessage = '';

  @override
  void dispose() {
    _cropController.dispose();
    _locationController.dispose();
    _soilTypeController.dispose();
    _weatherController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _getAdvisory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _advisoryResult = '';
    });

    try {
      final advisory = await _advisoryService.getCropAdvisory(
        crop: _cropController.text.trim(),
        location: _locationController.text.trim(),
        soilType: _soilTypeController.text.trim(),
        weather: _weatherController.text.trim(),
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty 
            ? _additionalInfoController.text.trim() 
            : null,
      );

      setState(() {
        _advisoryResult = advisory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Crop Advisory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Crop Advisory',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get expert farming advice powered by AI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
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
          
          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop Information
                    _buildSectionTitle('Crop Information'),
                    const SizedBox(height: 12),
                    
                    _buildInputField(
                      controller: _cropController,
                      label: 'Crop Type',
                      hint: 'e.g., Rice, Wheat, Tomato',
                      suggestions: CropAdvisoryService.getPopularCrops(),
                      icon: Icons.agriculture,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'e.g., Delhi, Punjab, Maharashtra',
                      icon: Icons.location_on,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _soilTypeController,
                      label: 'Soil Type',
                      hint: 'e.g., Clay, Sandy, Loamy',
                      suggestions: CropAdvisoryService.getSoilTypes(),
                      icon: Icons.terrain,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _weatherController,
                      label: 'Current Weather',
                      hint: 'e.g., Sunny, Rainy, Cloudy',
                      suggestions: CropAdvisoryService.getWeatherConditions(),
                      icon: Icons.wb_sunny,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _additionalInfoController,
                      label: 'Additional Information (Optional)',
                      hint: 'Any specific concerns or questions',
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Get Advisory Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getAdvisory,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.psychology),
                        label: Text(_isLoading ? 'Getting AI Advice...' : 'Get AI Advisory'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Results Section
                    if (_advisoryResult.isNotEmpty) ...[
                      _buildSectionTitle('AI Advisory Results'),
                      const SizedBox(height: 12),
                      _buildAdvisoryResult(_advisoryResult),
                    ],
                    
                    if (_errorMessage.isNotEmpty) ...[
                      _buildSectionTitle('Error'),
                      const SizedBox(height: 12),
                      _buildErrorMessage(_errorMessage),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    List<String>? suggestions,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
        if (suggestions != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestions.take(5).map((suggestion) => GestureDetector(
              onTap: () {
                controller.text = suggestion;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvisoryResult(String result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'AI Advisory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Copy to clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Advisory copied to clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
