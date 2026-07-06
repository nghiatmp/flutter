import 'package:flutter/material.dart';

class CustomRadioGroupField<T> extends StatelessWidget {
  const CustomRadioGroupField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.optionLabelBuilder,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final List<T> options;
  final T? value;
  final String Function(T option) optionLabelBuilder;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            RadioGroup<T>(
              groupValue: field.value,
              onChanged: (newValue) {
                field.didChange(newValue);
                onChanged(newValue);
              },
              child: Wrap(
                spacing: 8,
                children: options.map((option) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<T>(value: option),
                      Text(optionLabelBuilder(option)),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (field.hasError) _FieldError(field.errorText!),
          ],
        );
      },
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
