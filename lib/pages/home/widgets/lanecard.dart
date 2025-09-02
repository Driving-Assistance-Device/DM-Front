import 'package:flutter/material.dart';

class LaneIndicator extends StatelessWidget {
  final double value;
  final double width;
  final double height;

  const LaneIndicator({
    super.key,
    required this.value,
    this.width = 300,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(-50.0, 50.0);
    final normalizedValue = (safeValue + 50) / 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(148, 149, 174, 236),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Center(
                child: Container(
                  height: height,
                  width: 10,
                  color: const Color.fromRGBO(35, 21, 157, 1),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: normalizedValue,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(normalizedValue * 2 - 1, 0),
                child: const Icon(
                  Icons.directions_car,
                  size: 70,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('좌', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('우', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
