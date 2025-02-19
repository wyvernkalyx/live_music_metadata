import 'package:flutter/material.dart';

class InfoFieldWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isReadOnly;
  final ValueChanged<String>? onChanged;

  const InfoFieldWidget({
    super.key,
    required this.label,
    required this.value,
    this.isReadOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (isReadOnly)
          Text(
            value.isEmpty ? '(Not set)' : value,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty ? Colors.grey : Colors.white,
            ),
          )
        else
          TextFormField(
            initialValue: value,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty ? Colors.grey : Colors.white,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A row of two info fields with equal width
class InfoFieldRow extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;
  final ValueChanged<String>? onChanged1;
  final ValueChanged<String>? onChanged2;

  const InfoFieldRow({
    super.key,
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
    this.onChanged1,
    this.onChanged2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoFieldWidget(
            label: label1,
            value: value1,
            onChanged: onChanged1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InfoFieldWidget(
            label: label2,
            value: value2,
            onChanged: onChanged2,
          ),
        ),
      ],
    );
  }
}