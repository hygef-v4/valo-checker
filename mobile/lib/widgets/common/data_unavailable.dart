import 'package:flutter/material.dart';

/// Honest empty state shown when Riot did not return the data for a section.
/// Never substitute placeholder or invented values for it.
class DataUnavailable extends StatelessWidget {
  final String message;

  const DataUnavailable({
    super.key,
    this.message = 'Detailed data is unavailable for this match.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
