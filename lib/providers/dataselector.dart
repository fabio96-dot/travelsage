import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime? initialDateFallback;  // fallback per initialDate
  final void Function(DateTime) onDateSelected;

  const DateSelector({
    super.key,
    required this.label,
    required this.selectedDate,
    this.initialDateFallback,
    required this.onDateSelected,
  });

  Future<void> _pickDate(BuildContext context) async {
    final initial = selectedDate ?? initialDateFallback ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          selectedDate == null
              ? 'Seleziona'
              : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
          style: selectedDate == null
              ? const TextStyle(color: Colors.grey)
              : null,
        ),
      ),
    );
  }
}
