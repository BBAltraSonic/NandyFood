import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:food_delivery_app/core/constants/config.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/features/order/presentation/screens/payment_confirmation_screen.dart';
import 'package:food_delivery_app/shared/widgets/payment_security_badge.dart';
import 'package:food_delivery_app/shared/widgets/payment_loading_indicator.dart';

/// Screen for PayFast payment using WebView
class PayFastPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, String> paymentData;
  final String orderId;
  final double amount;

  const PayFastPaymentScreen({
    super.key,
    required this.paymentData,
    required this.orderId,
    required this.amount,
  });

  @override
  ConsumerState<PayFastPaymentScreen> createState() =>
      _PayFastPaymentScreenState();
}

class _PayFastPaymentScreenState extends ConsumerState<PayFastPaymentScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    AppLogger.function('PayFastPaymentScreen._initializeWebView', 'ENTER');

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              AppLogger.http('GET', url);
              setState(() => _isLoading = true);
            },
            onPageFinished: (url) {
              AppLogger.info('Page loaded', data: {'url': url});
              setState(() => _isLoading = false);
            },
            onNavigationRequest: _handleNavigationRequest,
            onWebResourceError: (error) {
              AppLogger.error('WebView error', error: error.description);
              setState(() {
                _errorMessage = error.description;
                _isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(_buildPayFastUrl());

      AppLogger.success('WebView initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize WebView', error: e, stack: stack);
      setState(() {
        _errorMessage = 'Failed to load payment page';
        _isLoading = false;
      });
    }
  }

  Uri _buildPayFastUrl() {
    final baseUrl = Config.payfastApiUrl;
    AppLogger.info('Building PayFast URL', data: {'baseUrl': baseUrl});

    return Uri.parse(baseUrl).replace(
      queryParameters: widget.paymentData,
    );
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    AppLogger.function('PayFastPaymentScreen._handleNavigationRequest', 'ENTER',
        params: {'url': request.url});

    // Check for success return URL
    if (request.url.contains('payment/success') ||
        request.url.contains(Config.payfastReturnUrl)) {
      AppLogger.success('Payment success URL detected');
      _handlePaymentSuccess(request.url);
      return NavigationDecision.prevent;
    }

    // Check for cancel URL
    if (request.url.contains('payment/cancel') ||
        request.url.contains(Config.payfastCancelUrl)) {
      AppLogger.warning('Payment cancel URL detected');
      _handlePaymentCancel();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handlePaymentSuccess(String url) async {
    AppLogger.function('PayFastPaymentScreen._handlePaymentSuccess', 'ENTER',
        params: {'url': url});

    try {
      setState(() => _isLoading = true);

      // Parse URL parameters
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      AppLogger.info('Payment response params', data: params);

      // Process payment response
      final paymentNotifier = ref.read(paymentProvider.notifier);
      final success = await paymentNotifier.processPaymentResponse(params);

      if (mounted) {
        // Navigate to confirmation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              orderId: widget.orderId,
              success: success,
              paymentReference: params['m_payment_id'],
              errorMessage: success ? null : 'Payment processing failed',
            ),
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to process payment success',
          error: e, stack: stack);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              orderId: widget.orderId,
              success: false,
              errorMessage: 'Failed to verify payment. Please contact support.',
            ),
          ),
        );
      }
    }
  }

  void _handlePaymentCancel() {
    AppLogger.function('PayFastPaymentScreen._handlePaymentCancel', 'ENTER');

    ref.read(paymentProvider.notifier).cancelPayment(null);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? Your order will not be placed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _handlePaymentCancel();
    }

    return false; // Prevent default back action
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.pop(context);
                }
              },
              tooltip: 'Cancel Payment',
            ),
          ],
        ),
        body: Stack(
          children: [
            // WebView
            if (_errorMessage == null)
              WebViewWidget(controller: _controller)
            else
              _buildErrorView(theme),

            // Loading indicator
            if (_isLoading)
              const PaymentLoadingIndicator(
                message: 'Loading secure payment page...',
                estimatedSeconds: 5,
              ),

            // Security badge at top
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const PaymentSecurityBadge(
                    variant: SecurityBadgeVariant.compact,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Payment Page',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initializeWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
