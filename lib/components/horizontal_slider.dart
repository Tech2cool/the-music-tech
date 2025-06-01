import 'package:flutter/material.dart';

class HorizontalSlider extends StatelessWidget {
  final String title;
  final List<Widget> childrens;
  final List<Widget> headers;

  const HorizontalSlider({
    super.key,
    required this.title,
    required this.childrens,
    this.headers = const [],
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
              ),
              ...headers,
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
