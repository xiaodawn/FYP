import 'package:flutter/material.dart';

class CardforSlider extends StatelessWidget {

  CardforSlider({@required this.colour, @required this.cardChild});

  final Color colour;
  final Widget cardChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: cardChild,             //for slider to happen, cardchild is required
      margin: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Color(0xFFFFECC9),
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }
}

// This file is for the slider box in the application.
// StatelessWidget is widget when users interacts, it will not change any features/
// This box will not change but the sliders do.

// Container role is a parent widget that manages all the child widget.
// Container basically store all the contents, which uses margin, border and padding to decorate the child widget.

