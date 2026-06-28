import 'package:flutter/material.dart';

class CustomDateField extends StatefulWidget {
  const CustomDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.hintText,
    this.prefixIcon,
    this.initialDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? hintText;
  final IconData? prefixIcon;
  final DateTime? initialDate;
  final FormFieldValidator<DateTime>? validator;

  @override
  State<CustomDateField> createState() => _CustomDateFieldState();
}

class _CustomDateFieldState extends State<CustomDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatDate(widget.value));
  }

  @override
  void didUpdateWidget(covariant CustomDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = _formatDate(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.value ?? widget.initialDate ?? widget.lastDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (pickedDate == null) return;

    _controller.text = _formatDate(pickedDate);
    field.didChange(pickedDate);
    widget.onChanged(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (field) {
        return TextFormField(
          controller: _controller,
          readOnly: true,
          onTap: () => _pickDate(field),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
            errorText: field.errorText,
          ),
        );
      },
    );
  }
}
