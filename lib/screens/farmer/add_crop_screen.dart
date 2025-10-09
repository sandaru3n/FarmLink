import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import 'map_location_picker_screen.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minBidPriceController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  File? _selectedImage;
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  
  // Location data
  double? _pickupLatitude;
  double? _pickupLongitude;

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _minBidPriceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLatitude: _pickupLatitude,
          initialLongitude: _pickupLongitude,
          initialAddress: _pickupLocationController.text.isNotEmpty 
              ? _pickupLocationController.text 
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLatitude = result['latitude'];
        _pickupLongitude = result['longitude'];
        _pickupLocationController.text = result['address'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitCrop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop image')),
      );
      return;
    }
    if (_startDate == null || _endDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates and times')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create start and end DateTime objects
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Upload image to Firebase Storage
      String imageUrl;
      try {
        imageUrl = await _storageService.uploadCropImage(_selectedImage!);
      } catch (e) {
        if (mounted) {
          // Show error dialog with retry option
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Image Upload Failed'),
              content: Text('Failed to upload image: $e\n\nWould you like to retry or continue without an image?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Continue without image'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
          
          if (shouldRetry == true) {
            // Retry upload
            try {
              imageUrl = await _storageService.uploadCropImage(_selectedImage!);
            } catch (retryError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Upload failed again: $retryError')),
                );
              }
              return;
            }
          } else {
            // Use placeholder image
            imageUrl = 'https://via.placeholder.com/300x200?text=Crop+Image';
          }
        }
        return;
      }

      final crop = CropModel(
        id: '',
        farmerId: authProvider.userProfile?.uid ?? '',
        cropName: _cropNameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        imageUrl: imageUrl,
        minBidPrice: double.parse(_minBidPriceController.text),
        startDate: startDateTime,
        endDate: endDateTime,
        pickupLocation: _pickupLocationController.text.trim(),
        pickupLatitude: _pickupLatitude,
        pickupLongitude: _pickupLongitude,
        createdAt: DateTime.now(),
      );

      final success = await cropProvider.addCrop(crop);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crop added successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(cropProvider.error ?? 'Failed to add crop')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Crop'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Crop Image
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add crop image',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
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
              const SizedBox(height: 16),

              // Crop Name
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter crop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and Min Bid Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (kg)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minBidPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Bid Price (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter minimum bid price';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start Date and Time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bidding Start',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : 'Select Date',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time),
                                    const SizedBox(width: 8),
                                    Text(
                                      _startTime != null
                                          ? _startTime!.format(context)
                                          : 'Select Time',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date and Time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bidding End',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Text(
                                      _endDate != null
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Select Date',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time),
                                    const SizedBox(width: 8),
                                    Text(
                                      _endTime != null
                                          ? _endTime!.format(context)
                                          : 'Select Time',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Location with Map Picker
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pickup Location',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pickupLocationController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tap "Select on Map" to choose location',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                          suffixIcon: _pickupLatitude != null && _pickupLongitude != null
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please select pickup location using the map';
                          }
                          return null;
                        },
                      ),
                      if (_pickupLatitude != null && _pickupLongitude != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Coordinates: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitCrop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Crop Listing',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
