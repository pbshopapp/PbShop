import 'package:flutter/material.dart';

class RatingBar extends StatefulWidget {
  final Function(int) onRatingSelected;
  const RatingBar({super.key, required this.onRatingSelected});

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
            widget.onRatingSelected(_rating);
          },
        );
      }),
    );
  }
}