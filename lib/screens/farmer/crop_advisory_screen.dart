import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/crop_advisory_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_localizations.dart';

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
  bool _useAutoDetection = true; // Auto-detect location and weather by default

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
    // Only validate required fields based on auto-detection mode
    if (_useAutoDetection) {
      // Only validate crop and soil type when using auto-detection
      if (_cropController.text.trim().isEmpty || _soilTypeController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter crop type and soil type';
        });
        return;
      }
    } else {
      // Validate all fields when using manual input
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _advisoryResult = '';
    });

    try {
      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.uid;

      final advisory = await _advisoryService.getCropAdvisory(
        crop: _cropController.text.trim(),
        soilType: _soilTypeController.text.trim(),
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty 
            ? _additionalInfoController.text.trim() 
            : null,
        userId: userId, // Pass user ID for real data integration
        manualLocation: _useAutoDetection ? null : _locationController.text.trim(),
        manualWeather: _useAutoDetection ? null : _weatherController.text.trim(),
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

  /// Get advisory for farmer's existing crops
  Future<void> _getAdvisoryForExistingCrops() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.uid;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Please log in to get personalized advisory';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _advisoryResult = '';
    });

    try {
      final advisory = await _advisoryService.getAdvisoryForFarmerCrops(userId);

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade700,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'AI Crop Advisory',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 60),
                    child: Text(
                      'Get expert farming advice powered by AI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                    
                    // Auto-Detection Toggle
                    _buildAutoDetectionToggle(),
                    
                    const SizedBox(height: 16),
                    
                    // Location and Weather Fields (conditional)
                    if (!_useAutoDetection) ...[
                      _buildInputField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'e.g., Delhi, Punjab, Maharashtra',
                        icon: Icons.location_on,
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    _buildInputField(
                      controller: _soilTypeController,
                      label: 'Soil Type',
                      hint: 'e.g., Clay, Sandy, Loamy',
                      suggestions: CropAdvisoryService.getSoilTypes(),
                      icon: Icons.terrain,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Weather Field (conditional)
                    if (!_useAutoDetection) ...[
                      _buildInputField(
                        controller: _weatherController,
                        label: 'Current Weather',
                        hint: 'e.g., Sunny, Rainy, Cloudy',
                        suggestions: CropAdvisoryService.getWeatherConditions(),
                        icon: Icons.wb_sunny,
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                    
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
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade500,
                            Colors.green.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade300,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getAdvisory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.psychology, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Get AI Advisory',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Get Advisory for Existing Crops Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade500,
                            Colors.blue.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade300,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getAdvisoryForExistingCrops,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.agriculture, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Get Advisory for My Crops',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
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
                    const SizedBox(height: 80),
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
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: Colors.green.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
        if (suggestions != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(5).map((suggestion) => GestureDetector(
              onTap: () {
                controller.text = suggestion;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade100,
                      Colors.green.shade200,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Advisory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Copy to clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Advisory copied to clipboard'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                },
                icon: Icon(Icons.copy, color: Colors.green.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildFormattedAdvisoryText(result),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAdvisoryText(String result) {
    // Split the result into lines
    final lines = result.split('\n');
    List<Widget> widgets = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check if it's a title (starts with ##)
      if (line.startsWith('##')) {
        widgets.add(_buildTitleWidget(line));
        widgets.add(const SizedBox(height: 12));
      }
      // Check if it's a bullet point
      else if (line.startsWith('•') || line.startsWith('-')) {
        widgets.add(_buildBulletPointWidget(line));
        widgets.add(const SizedBox(height: 6));
      }
      // Check if it's a numbered item
      else if (RegExp(r'^\d+\.').hasMatch(line)) {
        widgets.add(_buildNumberedItemWidget(line));
        widgets.add(const SizedBox(height: 6));
      }
      // Regular paragraph
      else {
        widgets.add(_buildParagraphWidget(line));
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTitleWidget(String line) {
    // Clean up the title (remove ##)
    String cleanTitle = line.replaceAll(RegExp(r'^#+\s*'), '');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade100,
            Colors.green.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Text(
        cleanTitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildBulletPointWidget(String line) {
    // Clean up the bullet point (remove bullet and ** formatting)
    String cleanLine = line.replaceFirst(RegExp(r'^[•\-]\s*'), '').replaceAll(RegExp(r'\*\*'), '');
    
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanLine,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItemWidget(String line) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              line.split('.')[0],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line.replaceFirst(RegExp(r'^\d+\.\s*'), '').replaceAll(RegExp(r'\*\*'), ''),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphWidget(String line) {
    return Text(
      line.replaceAll(RegExp(r'\*\*'), ''),
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDetectionToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: Colors.green.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Auto-Detection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              Switch(
                value: _useAutoDetection,
                onChanged: (value) {
                  setState(() {
                    _useAutoDetection = value;
                  });
                },
                activeColor: Colors.green.shade600,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _useAutoDetection 
              ? '📍 Location and 🌤️ Weather will be automatically detected using GPS and weather services'
              : '📍 Location and 🌤️ Weather will be entered manually',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (_useAutoDetection) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure location permissions are enabled for accurate detection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
