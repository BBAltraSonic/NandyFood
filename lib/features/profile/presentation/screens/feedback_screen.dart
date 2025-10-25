import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/providers/auth_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  
  FeedbackType _selectedType = FeedbackType.other;
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    Future.microtask(() {
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.user != null) {
        _emailController.text = authState.user!.email ?? '';
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Feedback type selector
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'your.email@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rating (only for rating type)
            if (_selectedType == FeedbackType.rating) ...[
              _buildRatingSelector(),
              const SizedBox(height: 16),
            ],

            // Message field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: _getMessageLabel(),
                hintText: _getMessageHint(),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              maxLines: 8,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  if (_selectedType == FeedbackType.rating) {
                    return null; // Message is optional for ratings
                  }
                  return 'Please enter your message';
                }
                if (value.length < 10 && _selectedType != FeedbackType.rating) {
                  return 'Please enter at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feedback Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(_getFeedbackTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              avatar: Icon(
                _getFeedbackTypeIcon(type),
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              selectedColor: Colors.deepOrange,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starRating = index + 1;
            return IconButton(
              icon: Icon(
                starRating <= _rating ? Icons.star : Icons.star_border,
                size: 40,
              ),
              color: Colors.amber,
              onPressed: () {
                setState(() => _rating = starRating);
              },
            );
          }),
        ),
        Center(
          child: Text(
            _getRatingLabel(_rating),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(_rating),
            ),
          ),
        ),
      ],
    );
  }

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.featureRequest:
        return 'Feature Request';
      case FeedbackType.improvement:
        return 'Improvement';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.compliment:
        return 'Compliment';
      case FeedbackType.support:
        return 'Support';
      case FeedbackType.rating:
        return 'App Rating';
      case FeedbackType.other:
        return 'Other';
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.featureRequest:
        return Icons.lightbulb;
      case FeedbackType.improvement:
        return Icons.trending_up;
      case FeedbackType.complaint:
        return Icons.sentiment_dissatisfied;
      case FeedbackType.compliment:
        return Icons.sentiment_very_satisfied;
      case FeedbackType.support:
        return Icons.help;
      case FeedbackType.rating:
        return Icons.star;
      case FeedbackType.other:
        return Icons.chat;
    }
  }

  String _getMessageLabel() {
    switch (_selectedType) {
      case FeedbackType.bug:
        return 'Bug Description';
      case FeedbackType.featureRequest:
        return 'Feature Description';
      case FeedbackType.rating:
        return 'Review (Optional)';
      default:
        return 'Message';
    }
  }

  String _getMessageHint() {
    switch (_selectedType) {
      case FeedbackType.bug:
        return 'Describe the bug and steps to reproduce...';
      case FeedbackType.featureRequest:
        return 'Describe the feature you\'d like to see...';
      case FeedbackType.improvement:
        return 'How can we improve?';
      case FeedbackType.complaint:
        return 'What went wrong?';
      case FeedbackType.compliment:
        return 'What did you enjoy?';
      case FeedbackType.support:
        return 'How can we help?';
      case FeedbackType.rating:
        return 'Tell us more about your experience (optional)...';
      case FeedbackType.other:
        return 'Your message...';
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedbackService = FeedbackService();
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? 'guest';

      String feedbackId;

      if (_selectedType == FeedbackType.rating) {
        feedbackId = await feedbackService.submitAppRating(
          userId: userId,
          email: _emailController.text,
          rating: _rating,
          review: _messageController.text.isNotEmpty 
              ? _messageController.text 
              : null,
        );
      } else {
        feedbackId = await feedbackService.submitFeedback(
          userId: userId,
          email: _emailController.text,
          type: _selectedType,
          message: _messageController.text,
          rating: _selectedType == FeedbackType.rating ? _rating : null,
        );
      }

      if (mounted) {
        _showSuccessDialog(feedbackId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String feedbackId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text('Thank You!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your feedback has been submitted successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: ${feedbackId.substring(0, 10)}...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close feedback screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
