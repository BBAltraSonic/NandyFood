import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';

class AddEditPaymentScreen extends ConsumerStatefulWidget {
  final String? paymentMethodId; // If null, it's adding a new method
  final bool isEditing;

  const AddEditPaymentScreen({
    Key? key,
    this.paymentMethodId,
    this.isEditing = false,
  }) : super(key: key);

  @override
  ConsumerState<AddEditPaymentScreen> createState() =>
      _AddEditPaymentScreenState();
}

class _AddEditPaymentScreenState extends ConsumerState<AddEditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  String _selectedBrand = 'Unknown';
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Payment Method' : 'Add Payment Method',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Card Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Card number field
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: _getBrandColor(_selectedBrand),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a card number';
                  }
                  if (value.replaceAll(RegExp(r'\s+'), '').length < 13) {
                    return 'Card number is too short';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Format card number as user types
                  String formattedValue = value.replaceAll(RegExp(r'\D'), '');
                  if (formattedValue.length > 16) {
                    formattedValue = formattedValue.substring(0, 16);
                  }

                  // Add spaces every 4 digits
                  String displayValue = '';
                  for (int i = 0; i < formattedValue.length; i++) {
                    if (i > 0 && i % 4 == 0) {
                      displayValue += ' ';
                    }
                    displayValue += formattedValue[i];
                  }

                  _cardNumberController.value = TextEditingValue(
                    text: displayValue,
                    selection: TextSelection.collapsed(
                      offset: displayValue.length,
                    ),
                  );

                  // Update brand based on card number
                  setState(() {
                    _selectedBrand = _getCardBrand(formattedValue);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Cardholder name field
              TextFormField(
                controller: _cardholderNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry date and CVC row
              Row(
                children: [
                  // Expiry month
                  Expanded(
                    child: TextFormField(
                      controller: _expiryMonthController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Month',
                        hintText: 'MM',
                        prefixIcon: Icon(Icons.date_range),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expiry month';
                        }
                        final month = int.tryParse(value);
                        if (month == null || month < 1 || month > 12) {
                          return 'Please enter a valid month (1-12)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.length == 2) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Expiry year
                  Expanded(
                    child: TextFormField(
                      controller: _expiryYearController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Year',
                        hintText: 'YY',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expiry year';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < 0 || year > 9) {
                          return 'Please enter a valid year (00-99)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // CVC
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter CVC';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'CVC must be 3 or 4 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Loading indicator or save button
              if (_isLoading)
                const Center(child: LoadingIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePaymentMethod,
                    child: Text(
                      widget.isEditing
                          ? 'Update Payment Method'
                          : 'Add Payment Method',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCardBrand(String cardNumber) {
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

    if (cleanCardNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanCardNumber.startsWith('5') ||
        cleanCardNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cleanCardNumber.startsWith('3')) {
      return 'Amex';
    } else {
      return 'Unknown';
    }
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade700;
      case 'mastercard':
        return Colors.red.shade700;
      case 'amex':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);

      await paymentMethodsNotifier.addPaymentMethod(
        cardNumber: _cardNumberController.text.replaceAll(RegExp(r'\s+'), ''),
        expiryMonth: int.parse(_expiryMonthController.text),
        expiryYear: int.parse(_expiryYearController.text),
        cvc: _cvcController.text,
        holderName: _cardholderNameController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to the payment methods screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
