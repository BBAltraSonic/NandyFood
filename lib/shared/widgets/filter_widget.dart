import 'package:flutter/material.dart';

class FilterWidget extends StatefulWidget {
  final List<FilterOption> options;
  final ValueChanged<List<FilterOption>>? onFiltersChanged;

  const FilterWidget({super.key, required this.options, this.onFiltersChanged});

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late List<FilterOption> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.options
        .where((option) => option.isSelected)
        .toList();
  }

  void _toggleOption(FilterOption option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
        option.isSelected = false;
      } else {
        _selectedOptions.add(option);
        option.isSelected = true;
      }
    });

    widget.onFiltersChanged?.call(_selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.options.map((option) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option.label),
              selected: option.isSelected,
              onSelected: (selected) {
                _toggleOption(option);
              },
              selectedColor: Colors.black54.withValues(alpha: 0.2),
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: option.isSelected
                    ? Colors.black54
                    : Colors.grey.shade700,
                fontWeight: option.isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: option.isSelected
                      ? Colors.black54
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FilterOption {
  final String id;
  final String label;
  bool isSelected;

  FilterOption({
    required this.id,
    required this.label,
    this.isSelected = false,
  });
}
