import 'package:flutter/material.dart';

class CustomDropdownField<T> extends StatelessWidget {
  const CustomDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.optionLabelBuilder,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
  });

  final String label;
  final List<T> options;
  final T? value;
  final String Function(T option) optionLabelBuilder;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      items: options.map((option) {
        return DropdownMenuItem<T>(
          value: option,
          child: Text(optionLabelBuilder(option)),
        );
      }).toList(),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
