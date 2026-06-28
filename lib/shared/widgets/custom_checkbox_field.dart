import 'package:flutter/material.dart';

class CustomCheckboxField extends StatelessWidget {
  const CustomCheckboxField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final FormFieldValidator<bool>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(label),
              value: field.value ?? false,
              onChanged: (checked) {
                final nextValue = checked ?? false;
                field.didChange(nextValue);
                onChanged(nextValue);
              },
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
