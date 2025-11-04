import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import '../providers/support_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({
    super.key,
    this.initialSubject,
    this.initialCategory,
    this.initialDescription,
    this.orderId,
    this.restaurantId,
  });

  final String? initialSubject;
  final SupportTicketCategory? initialCategory;
  final String? initialDescription;
  final String? orderId;
  final String? restaurantId;

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  SupportTicketCategory _selectedCategory = SupportTicketCategory.other;
  SupportTicketPriority _selectedPriority = SupportTicketPriority.medium;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with initial values if provided
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(supportProvider.notifier).createTicket(
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        orderId: widget.orderId,
        restaurantId: widget.restaurantId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket created successfully'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: $e'),
            backgroundColor: Colors.black54,
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

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject field
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Brief description of your issue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject';
                          }
                          if (value.trim().length < 3) {
                            return 'Subject must be at least 3 characters';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),

                      // Category selection
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SupportTicketCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return FilterChip(
                            label: Text(category.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            checkmarkColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Priority selection
                      const Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: SupportTicketPriority.values.map((priority) {
                          final isSelected = _selectedPriority == priority;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPriority = priority;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getPriorityColor(priority)
                                            .withOpacity(0.2)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? _getPriorityColor(priority)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getPriorityIcon(priority),
                                        color: _getPriorityColor(priority),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        priority.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? _getPriorityColor(priority)
                                              : Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Please provide detailed information about your issue',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.description),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                        maxLines: 6,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: 24),

                      // Help text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Our support team will review your ticket and respond within 24 hours.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.low:
        return Colors.black26;      // Light gray (was green)
      case SupportTicketPriority.medium:
        return Colors.black54;      // Medium gray (was orange)
      case SupportTicketPriority.high:
        return Colors.black87;      // Dark gray (was red)
      case SupportTicketPriority.urgent:
        return Colors.black;        // Pure black (was purple)
    }
  }

  IconData _getPriorityIcon(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.low:
        return Icons.arrow_downward;
      case SupportTicketPriority.medium:
        return Icons.remove;
      case SupportTicketPriority.high:
        return Icons.arrow_upward;
      case SupportTicketPriority.urgent:
        return Icons.priority_high;
    }
  }
}