import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TipSelector extends StatefulWidget {
  final double subtotal;
  final double currentTip;
  final Function(double) onTipChanged;

  const TipSelector({
    super.key,
    required this.subtotal,
    required this.currentTip,
    required this.onTipChanged,
  });

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  TipOption _selectedOption = TipOption.fifteen;
  final TextEditingController _customTipController = TextEditingController();
  bool _isCustomSelected = false;

  @override
  void initState() {
    super.initState();
    _initializeTipSelection();
  }

  @override
  void dispose() {
    _customTipController.dispose();
    super.dispose();
  }

  void _initializeTipSelection() {
    // Check if current tip matches any preset
    final tip10 = widget.subtotal * 0.10;
    final tip15 = widget.subtotal * 0.15;
    final tip20 = widget.subtotal * 0.20;

    if ((widget.currentTip - tip10).abs() < 0.01) {
      _selectedOption = TipOption.ten;
    } else if ((widget.currentTip - tip15).abs() < 0.01) {
      _selectedOption = TipOption.fifteen;
    } else if ((widget.currentTip - tip20).abs() < 0.01) {
      _selectedOption = TipOption.twenty;
    } else if (widget.currentTip == 0) {
      _selectedOption = TipOption.none;
    } else {
      _isCustomSelected = true;
      _customTipController.text = widget.currentTip.toStringAsFixed(2);
    }
  }

  void _handleTipSelection(TipOption option) {
    setState(() {
      _selectedOption = option;
      _isCustomSelected = false;
      _customTipController.clear();
    });

    double tipAmount = 0.0;
    switch (option) {
      case TipOption.none:
        tipAmount = 0.0;
        break;
      case TipOption.ten:
        tipAmount = widget.subtotal * 0.10;
        break;
      case TipOption.fifteen:
        tipAmount = widget.subtotal * 0.15;
        break;
      case TipOption.twenty:
        tipAmount = widget.subtotal * 0.20;
        break;
    }

    widget.onTipChanged(tipAmount);
  }

  void _handleCustomTip(String value) {
    setState(() {
      _isCustomSelected = true;
    });

    if (value.isEmpty) {
      widget.onTipChanged(0.0);
      return;
    }

    final tipAmount = double.tryParse(value) ?? 0.0;
    widget.onTipChanged(tipAmount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Add a Tip',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Support your delivery driver',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Preset tip options
          Row(
            children: [
              Expanded(
                child: _buildTipButton(
                  context,
                  'No Tip',
                  TipOption.none,
                  '\$0',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTipButton(
                  context,
                  '10%',
                  TipOption.ten,
                  '\$${(widget.subtotal * 0.10).toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTipButton(
                  context,
                  '15%',
                  TipOption.fifteen,
                  '\$${(widget.subtotal * 0.15).toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTipButton(
                  context,
                  '20%',
                  TipOption.twenty,
                  '\$${(widget.subtotal * 0.20).toStringAsFixed(2)}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom tip input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTipController,
                  decoration: InputDecoration(
                    labelText: 'Custom Tip',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _isCustomSelected
                            ? theme.primaryColor
                            : Colors.grey[300]!,
                        width: _isCustomSelected ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: _handleCustomTip,
                  onTap: () {
                    setState(() {
                      _isCustomSelected = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(
    BuildContext context,
    String label,
    TipOption option,
    String amount,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedOption == option && !_isCustomSelected;

    return InkWell(
      onTap: () => _handleTipSelection(option),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TipOption {
  none,
  ten,
  fifteen,
  twenty,
}
