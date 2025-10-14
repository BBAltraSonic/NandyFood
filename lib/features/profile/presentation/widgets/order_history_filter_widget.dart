import 'package:flutter/material.dart';

class OrderHistoryFilterWidget extends StatefulWidget {
  final Function(String status)? onFilterChanged;

  const OrderHistoryFilterWidget({Key? key, this.onFilterChanged}) : super(key: key);

  @override
  State<OrderHistoryFilterWidget> createState() => _OrderHistoryFilterWidgetState();
}

class _OrderHistoryFilterWidgetState extends State<OrderHistoryFilterWidget> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Completed',
    'Pending',
    'Cancelled',
    'Refunded'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: _selectedFilter == filter
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              selected: _selectedFilter == filter,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'All';
                });
                if (widget.onFilterChanged != null) {
                  widget.onFilterChanged!(_selectedFilter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}