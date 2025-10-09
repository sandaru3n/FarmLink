import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.amber.shade600,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade600,
              Colors.amber.shade500,
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.15, 0.15],
          ),
        ),
        child: Column(
          children: [
            // Modern Gradient Header
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade600,
                    Colors.amber.shade500,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${widget.order.id.substring(widget.order.id.length - 6)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close, 
                        color: Colors.white,
                        size: 28,
                        weight: 900,
                      ),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              
              // Distributor Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade50.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.order.items.first.distributorName.isNotEmpty
                              ? widget.order.items.first.distributorName[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.order.items.first.distributorName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey.shade900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.order.items.length} item${widget.order.items.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Star Rating
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade50,
                      Colors.orange.shade50.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade100, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How was your overall experience?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = (index + 1).toDouble();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: index < _rating 
                                  ? Colors.amber.shade100 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: index < _rating ? Colors.amber.shade700 : Colors.grey.shade400,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    if (_rating > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade600, Colors.amber.shade700],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _getRatingText(_rating),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Categories
              Row(
                children: [
                  Icon(Icons.thumb_up_outlined, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'What aspects did you like? (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.remove(category);
                        } else {
                          _selectedCategories.add(category);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Colors.blue.shade600, Colors.blue.shade700],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Comment
              Row(
                children: [
                  Icon(Icons.rate_review_outlined, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Write a review (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this order...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Icon(Icons.edit_note, color: Colors.grey.shade400),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              
              const SizedBox(height: 18),
              
              // Feedback
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Additional feedback (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Any suggestions for improvement?',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Icon(Icons.tips_and_updates, color: Colors.orange.shade400),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              
                    ],
                  ),
                ),
              ),
            ),
            
            // Fixed Action Buttons at Bottom
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide.none,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _rating > 0 && !_isSubmitting
                            ? LinearGradient(
                                colors: [Colors.amber.shade600, Colors.amber.shade700],
                              )
                            : null,
                        color: _rating > 0 && !_isSubmitting ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _rating > 0 && !_isSubmitting
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.existingRating != null ? Icons.edit : Icons.send_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.existingRating != null ? 'Update Review' : 'Submit Review',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
