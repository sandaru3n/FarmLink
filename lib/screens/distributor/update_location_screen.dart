import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../farmer/map_location_picker_screen.dart';

class UpdateLocationScreen extends StatefulWidget {
  const UpdateLocationScreen({super.key});

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.uid;

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _locationController.text = data['location'] ?? '';
            _latitude = data['latitude']?.toDouble();
            _longitude = data['longitude']?.toDouble();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _locationController.text.isNotEmpty 
              ? _locationController.text 
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'];
      });
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'location': _locationController.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
          'locationUpdatedAt': Timestamp.fromDate(DateTime.now()),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update My Location'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Set your default delivery location. This will be pre-filled when placing orders.',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Field with Map Picker
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'My Location',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openMapPicker,
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('Select on Map'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tap "Select on Map" to choose your location',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                                suffixIcon: _latitude != null && _longitude != null
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please select your location using the map';
                                }
                                return null;
                              },
                            ),
                            if (_latitude != null && _longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Location Confirmed',
                                              style: TextStyle(
                                                color: Colors.green[900],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
