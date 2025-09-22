import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final double initialRating;
  final int starCount;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;
  final bool readOnly;
  final Function(double)? onRatingChanged;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0.0,
    this.starCount = 5,
    this.starSize = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = false,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        return GestureDetector(
          onTap: widget.readOnly ? null : () => _onStarTapped(index),
          child: _buildStar(index),
        );
      }),
    );
  }

  Widget _buildStar(int index) {
    double starRating = index + 1.0;
    
    if (widget.allowHalfRating) {
      if (_currentRating >= starRating) {
        return Icon(
          Icons.star,
          color: widget.activeColor,
          size: widget.starSize,
        );
      } else if (_currentRating >= starRating - 0.5) {
        return Icon(
          Icons.star_half,
          color: widget.activeColor,
          size: widget.starSize,
        );
      } else {
        return Icon(
          Icons.star_border,
          color: widget.inactiveColor,
          size: widget.starSize,
        );
      }
    } else {
      if (_currentRating >= starRating) {
        return Icon(
          Icons.star,
          color: widget.activeColor,
          size: widget.starSize,
        );
      } else {
        return Icon(
          Icons.star_border,
          color: widget.inactiveColor,
          size: widget.starSize,
        );
      }
    }
  }

  void _onStarTapped(int index) {
    if (widget.readOnly) return;

    double newRating = index + 1.0;
    
    setState(() {
      _currentRating = newRating;
    });

    widget.onRatingChanged?.call(newRating);
  }

  // Method to get current rating (useful for parent widgets)
  double get currentRating => _currentRating;

  // Method to update rating programmatically
  void updateRating(double rating) {
    setState(() {
      _currentRating = rating;
    });
  }
}

// Read-only star rating widget for displaying ratings
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int starCount;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.starSize = 20.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return _buildStar(index);
      }),
    );
  }

  Widget _buildStar(int index) {
    double starRating = index + 1.0;
    
    if (allowHalfRating) {
      if (rating >= starRating) {
        return Icon(
          Icons.star,
          color: activeColor,
          size: starSize,
        );
      } else if (rating >= starRating - 0.5) {
        return Icon(
          Icons.star_half,
          color: activeColor,
          size: starSize,
        );
      } else {
        return Icon(
          Icons.star_border,
          color: inactiveColor,
          size: starSize,
        );
      }
    } else {
      if (rating >= starRating) {
        return Icon(
          Icons.star,
          color: activeColor,
          size: starSize,
        );
      } else {
        return Icon(
          Icons.star_border,
          color: inactiveColor,
          size: starSize,
        );
      }
    }
  }
}
