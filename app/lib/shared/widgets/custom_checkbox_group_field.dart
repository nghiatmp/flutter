import 'package:flutter/material.dart';

class CustomCheckboxGroupField<T> extends StatelessWidget {
  const CustomCheckboxGroupField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.optionLabelBuilder,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final List<T> options;
  final Set<T> selectedValues;
  final String Function(T option) optionLabelBuilder;
  final ValueChanged<Set<T>> onChanged;
  final FormFieldValidator<Set<T>>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<Set<T>>(
      initialValue: Set<T>.from(selectedValues),
      validator: validator,
      builder: (field) {
        final currentValues = field.value ?? <T>{};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((option) {
                return SizedBox(
                  width: 150,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(optionLabelBuilder(option)),
                    value: currentValues.contains(option),
                    onChanged: (checked) {
                      final nextValues = Set<T>.from(currentValues);
                      if (checked ?? false) {
                        nextValues.add(option);
                      } else {
                        nextValues.remove(option);
                      }
                      field.didChange(nextValues);
                      onChanged(nextValues);
                    },
                  ),
                );
              }).toList(),
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
