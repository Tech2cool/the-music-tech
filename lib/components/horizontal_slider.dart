import 'package:flutter/material.dart';

class HorizontalSlider extends StatelessWidget {
  final String title;
  final List<Widget> childrens;

  const HorizontalSlider({
    super.key,
    required this.title,
    required this.childrens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: childrens,
            ),
          ),
        ],
      ),
    );
  }
}
