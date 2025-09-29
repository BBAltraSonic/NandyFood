import 'package:flutter/material.dart';

class RememberMeCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String text;

  const RememberMeCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.text = 'Remember me',
  }) : super(key: key);

  @override
  State<RememberMeCheckbox> createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(RememberMeCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _value,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              setState(() {
                _value = newValue;
              });
              widget.onChanged?.call(newValue);
            }
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              final newValue = !_value;
              setState(() {
                _value = newValue;
              });
              widget.onChanged?.call(newValue);
            },
            child: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}