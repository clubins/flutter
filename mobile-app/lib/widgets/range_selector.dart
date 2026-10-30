import 'package:shadcn_flutter/shadcn_flutter.dart';

class RangeOption<T> {
  const RangeOption(this.value, this.label);
  final T value;
  final String label;
}

class RangeSelector<T> extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<RangeOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final option in options)
          Toggle(
            value: option.value == value,
            onChanged: (selected) {
              if (selected) onChanged(option.value);
            },
            child: Text(option.label),
          ),
      ],
    );
  }
}
