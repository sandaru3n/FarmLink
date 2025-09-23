import 'package:flutter/material.dart';
import '../../models/consumer_order_model.dart';
import '../../models/consumer_rating_model.dart';
import '../../services/consumer_rating_service.dart';

class ConsumerRatingDialog extends StatefulWidget {
  final ConsumerOrderModel order;
  final ConsumerRatingModel? existingRating;

  const ConsumerRatingDialog({
    super.key,
    required this.order,
    this.existingRating,
  });

  @override
  State<ConsumerRatingDialog> createState() => _ConsumerRatingDialogState();
}

class _ConsumerRatingDialogState extends State<ConsumerRatingDialog> {
  final ConsumerRatingService _ratingService = ConsumerRatingService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  
  double _rating = 0.0;
  bool _isSubmitting = false;
  List<String> _selectedCategories = [];

  final List<String> _availableCategories = [
    'Quality',
    'Delivery Speed',
    'Packaging',
    'Value for Money',
    'Customer Service',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _rating = widget.existingRating!.rating;
      _commentController.text = widget.existingRating!.comment ?? '';
      _feedbackController.text = widget.existingRating!.feedback ?? '';
      _selectedCategories = widget.existingRating!.categories ?? [];
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingRating != null 
                              ? 'Update Your Review'
                              : 'Rate Your Order',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order #${widget.order.id.substring(widget.order.id.length - 6)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Distributor Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        widget.order.items.first.distributorName.isNotEmpty
                            ? widget.order.items.first.distributorName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.items.first.distributorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.order.items.length} item${widget.order.items.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Star Rating
              const Text(
                'How was your overall experience?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = (index + 1).toDouble();
                        });
                      },
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
              ),
              
              if (_rating > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Categories
              const Text(
                'What aspects did you like? (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Comment
              const Text(
                'Write a review (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this order...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Feedback
              const Text(
                'Additional feedback (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any suggestions for improvement?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.existingRating != null ? 'Update Review' : 'Submit Review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 4.0) return 'Very Good!';
    if (rating >= 3.0) return 'Good!';
    if (rating >= 2.0) return 'Fair';
    return 'Poor';
  }

  Future<void> _submitRating() async {
    if (_rating <= 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.existingRating != null) {
        // Update existing rating
        await _ratingService.updateConsumerRating(
          ratingId: widget.existingRating!.id,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
          categories: _selectedCategories.isEmpty ? null : _selectedCategories,
        );
      } else {
        // Create new rating
        await _ratingService.createConsumerRating(
          consumerOrderId: widget.order.id,
          consumerId: widget.order.consumerId,
          distributorId: widget.order.items.first.distributorId,
          consumerName: widget.order.consumerName,
          distributorName: widget.order.items.first.distributorName,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
          categories: _selectedCategories.isEmpty ? null : _selectedCategories,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRating != null 
                ? 'Review updated successfully!' 
                : 'Thank you for your review!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
