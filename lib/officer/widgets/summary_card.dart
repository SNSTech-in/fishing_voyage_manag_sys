import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  const SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
