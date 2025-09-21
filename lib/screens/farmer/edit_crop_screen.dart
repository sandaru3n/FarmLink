import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class EditCropScreen extends StatefulWidget {
  final CropModel crop;

  const EditCropScreen({super.key, required this.crop});

  @override
  State<EditCropScreen> createState() => _EditCropScreenState();
}

class _EditCropScreenState extends State<EditCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minBidPriceController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imageUrl;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _cropNameController.text = widget.crop.cropName;
    _quantityController.text = widget.crop.quantity.toString();
    _minBidPriceController.text = widget.crop.minBidPrice.toString();
    _pickupLocationController.text = widget.crop.pickupLocation;
    _startDate = widget.crop.startDate;
    _endDate = widget.crop.endDate;
    _imageUrl = widget.crop.imageUrl;
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _minBidPriceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Crop'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop Image
              if (_imageUrl != null) ...[
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Crop Name
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
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
                        if (value == null || value.isEmpty) {
                          return 'Please enter minimum bid price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pickup Location
              TextFormField(
                controller: _pickupLocationController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                title: const Text('Bidding Start Date'),
                subtitle: Text(
                  _startDate != null 
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} at ${_startDate!.hour}:${_startDate!.minute.toString().padLeft(2, '0')}'
                      : 'Select start date',
                ),
                leading: const Icon(Icons.schedule),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectStartDate(),
              ),
              const SizedBox(height: 16),

              // End Date
              ListTile(
                title: const Text('Bidding End Date'),
                subtitle: Text(
                  _endDate != null 
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year} at ${_endDate!.hour}:${_endDate!.minute.toString().padLeft(2, '0')}'
                      : 'Select end date',
                ),
                leading: const Icon(Icons.event),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectEndDate(),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Crop',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateCrop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      setState(() {
        _error = 'Please select both start and end dates';
      });
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _error = 'End date must be after start date';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      
      final updatedCrop = CropModel(
        id: widget.crop.id,
        farmerId: widget.crop.farmerId,
        cropName: _cropNameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        imageUrl: _imageUrl ?? widget.crop.imageUrl,
        minBidPrice: double.parse(_minBidPriceController.text),
        startDate: _startDate!,
        endDate: _endDate!,
        pickupLocation: _pickupLocationController.text.trim(),
        status: 'pending', // Keep as pending
        createdAt: widget.crop.createdAt,
        bids: widget.crop.bids,
        order: widget.crop.order,
      );

      final success = await cropProvider.updateCrop(widget.crop.id, updatedCrop);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        setState(() {
          _error = cropProvider.error ?? 'Failed to update crop';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
