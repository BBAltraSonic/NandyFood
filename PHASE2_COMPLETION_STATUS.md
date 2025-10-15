# Phase 2 Implementation - Completion Status

**Date:** January 14, 2025  
**Session:** Phase 2 UI & Integration  
**Status:** 85% Complete

---

## Completed Components ✅

### 1. State Management Providers (100% Complete)
- ✅ **payment_provider.dart** - Full payment flow state management
  - Payment initialization
  - Payment response processing
  - Status verification
  - Error handling
  - Cancellation support
  
- ✅ **payment_method_provider.dart** - Method selection state
  - Available methods loading
  - Method selection
  - Network-based availability
  - Validation logic

- ✅ **cart_provider.dart** - Updated with payment method support
  - Added `setPaymentMethod(String)` method
  - Changed payment method from enum to String ('cash' or 'payfast')
  - Backward compatible with existing cart functionality

### 2. Payment Widgets (100% Complete)
- ✅ **payment_method_card.dart** - Reusable payment method card
  - Selected state visualization
  - Disabled state handling
  - Recommended badge
  - Radio button integration
  
- ✅ **payment_security_badge.dart** - Trust indicators
  - Full variant (all security features)
  - Compact variant (lock + text)
  - Mini variant (icon only)
  - PayFast branding

- ✅ **payment_loading_indicator.dart** - Custom loading UI
  - Animated payment icon
  - Progress indicator
  - Countdown timer
  - Cancellable option

---

## Remaining Components (15%)

### 3. Payment Screens (TO BE COMPLETED)

#### A. Payment Method Selection Screen
**File:** `lib/features/order/presentation/screens/payment_method_screen.dart`

**Purpose:** Allow users to choose between Cash and PayFast payment

**Key Features:**
```dart
class PaymentMethodScreen extends ConsumerWidget {
  final String orderId;
  final double amount;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodState = ref.watch(paymentMethodProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: Column(
        children: [
          // Display available methods using PaymentMethodCard
          Expanded(
            child: ListView(
              children: methodState.availableMethods.map((method) {
                return PaymentMethodCard(
                  method: method,
                  isSelected: method.type == methodState.selectedMethod,
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier)
                       .selectMethod(method.type);
                  },
                );
              }).toList(),
            ),
          ),
          
          // Order amount display
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontSize: 18)),
                    Text('R ${amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleContinue(context, ref),
                    child: Text('Continue to Payment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleContinue(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.read(paymentMethodProvider).selectedMethod;
    
    // Update cart with selected method
    ref.read(cartProvider.notifier).setPaymentMethod(
      selectedMethod == PaymentMethodType.cash ? 'cash' : 'payfast'
    );
    
    // Return selected method to checkout
    Navigator.pop(context, selectedMethod);
  }
}
```

#### B. PayFast Payment WebView Screen
**File:** `lib/features/order/presentation/screens/payfast_payment_screen.dart`

**Purpose:** Display PayFast payment page and handle callbacks

**Key Features:**
```dart
import 'package:webview_flutter/webview_flutter.dart';

class PayFastPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, String> paymentData;
  final String orderId;
  final double amount;
  
  @override
  ConsumerState<PayFastPaymentScreen> createState() => _PayFastPaymentScreenState();
}

class _PayFastPaymentScreenState extends ConsumerState<PayFastPaymentScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(_buildPayFastUrl());
  }
  
  Uri _buildPayFastUrl() {
    final baseUrl = Config.payfastApiUrl;
    return Uri.parse(baseUrl).replace(queryParameters: widget.paymentData);
  }
  
  NavigationDecision _handleNavigation(NavigationRequest request) {
    if (request.url.contains('payment/success')) {
      _handlePaymentSuccess(request.url);
      return NavigationDecision.prevent;
    }
    if (request.url.contains('payment/cancel')) {
      _handlePaymentCancel();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }
  
  Future<void> _handlePaymentSuccess(String url) async {
    final params = Uri.parse(url).queryParameters;
    final paymentNotifier = ref.read(paymentProvider.notifier);
    
    final success = await paymentNotifier.processPaymentResponse(params);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            orderId: widget.orderId,
            success: success,
            paymentReference: params['m_payment_id'],
          ),
        ),
      );
    }
  }
  
  void _handlePaymentCancel() {
    ref.read(paymentProvider.notifier).cancelPayment(null);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cancel Payment?'),
            content: Text('Are you sure you want to cancel this payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes, Cancel'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Secure Payment'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _handlePaymentCancel,
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              PaymentLoadingIndicator(
                message: 'Loading secure payment page...',
                estimatedSeconds: 5,
              ),
            
            // Security badge at top
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PaymentSecurityBadge(variant: SecurityBadgeVariant.compact),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### C. Payment Confirmation Screen
**File:** `lib/features/order/presentation/screens/payment_confirmation_screen.dart`

**Purpose:** Show payment result with appropriate actions

**Key Features:**
```dart
class PaymentConfirmationScreen extends ConsumerWidget {
  final String orderId;
  final bool success;
  final String? paymentReference;
  final String? errorMessage;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async => success, // Allow back only if successful
      child: Scaffold(
        body: SafeArea(
          child: success ? _buildSuccessView(context) : _buildFailureView(context),
        ),
      ),
    );
  }
  
  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 60, color: Colors.green),
            ),
            
            SizedBox(height: 24),
            Text('Payment Successful!', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your order has been placed'),
            
            SizedBox(height: 32),
            
            // Order details card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Order Number', '#$orderId'),
                    _buildDetailRow('Payment Method', 'PayFast'),
                    if (paymentReference != null)
                      _buildDetailRow('Payment Ref', paymentReference!),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToTracking(context),
                child: Text('Track Order'),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFailureView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error, size: 60, color: Colors.red),
            ),
            
            SizedBox(height: 24),
            Text('Payment Failed', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(errorMessage ?? 'We couldn\'t process your payment'),
            
            SizedBox(height: 32),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Try Again'),
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Change payment method
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Use Different Method'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

---

### 4. Checkout Integration (TO BE COMPLETED)

**File:** `lib/features/order/presentation/screens/checkout_screen.dart`

**Changes Required:**

1. **Replace PaymentMethodSelectorCash widget** with button to open PaymentMethodScreen
2. **Update place order flow** to handle both cash and PayFast payments
3. **Add PayFast initialization** before navigating to WebView

**Key Code Changes:**
```dart
// In checkout_screen.dart, replace the payment selector:

// OLD CODE (remove):
const PaymentMethodSelectorCash(),

// NEW CODE (add):
Card(
  child: ListTile(
    leading: Icon(Icons.payment),
    title: Text('Payment Method'),
    subtitle: Text(
      cartState.paymentMethod == 'cash' 
        ? 'Cash on Delivery' 
        : 'Card Payment (PayFast)'
    ),
    trailing: Icon(Icons.chevron_right),
    onTap: () async {
      final selected = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(
            orderId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            amount: cartState.totalAmount,
          ),
        ),
      );
      
      // Method is already updated in cart by PaymentMethodScreen
    },
  ),
),

// Update _placeOrder method:
Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
  final cartState = ref.watch(cartProvider);
  final paymentMethod = cartState.paymentMethod;
  
  try {
    if (paymentMethod == 'cash') {
      // CASH FLOW: Create order directly
      await _placeCashOrder(context, ref);
      
    } else if (paymentMethod == 'payfast') {
      // PAYFAST FLOW: Initialize payment first
      final paymentNotifier = ref.read(paymentProvider.notifier);
      
      final paymentData = await paymentNotifier.initializePayment(
        orderId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_123', // Get from auth
        amount: cartState.totalAmount,
        itemName: 'Food Order',
        customerEmail: 'user@example.com', // Get from profile
      );
      
      // Navigate to PayFast WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayFastPaymentScreen(
            paymentData: paymentData,
            orderId: paymentData['m_payment_id']!,
            amount: cartState.totalAmount,
          ),
        ),
      );
    }
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${ErrorHandler.getErrorMessage(e)}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Quick Implementation Guide

### Step 1: Create Missing Screens (Estimated: 2-3 hours)
```bash
# Create these files with the code provided above:
1. lib/features/order/presentation/screens/payment_method_screen.dart
2. lib/features/order/presentation/screens/payfast_payment_screen.dart
3. lib/features/order/presentation/screens/payment_confirmation_screen.dart
```

### Step 2: Update Checkout Screen (Estimated: 1 hour)
```bash
# Update this file with the changes shown above:
lib/features/order/presentation/screens/checkout_screen.dart
```

### Step 3: Run Build and Analyze (Estimated: 30 min)
```bash
cd C:\Users\BB\Documents\NandyFood
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-infos
```

### Step 4: Test Payment Flow (Estimated: 1 hour)
- Test cash payment flow
- Test PayFast payment initialization
- Test payment success handling
- Test payment failure handling
- Test payment cancellation

---

## Testing Checklist

### Unit Tests
- [ ] PaymentNotifier state transitions
- [ ] Payment method selection
- [ ] Payment data generation
- [ ] Error handling

### Widget Tests
- [ ] PaymentMethodCard rendering
- [ ] PaymentSecurityBadge variants
- [ ] PaymentLoadingIndicator animation
- [ ] PaymentMethodScreen selection
- [ ] PaymentConfirmationScreen states

### Integration Tests
- [ ] Complete cash payment flow
- [ ] Complete PayFast payment flow (sandbox)
- [ ] Payment cancellation flow
- [ ] Network error handling
- [ ] Payment verification

---

## Current File Structure

```
lib/
├── features/
│   └── order/
│       └── presentation/
│           ├── providers/
│           │   ├── payment_provider.dart ✅ DONE
│           │   ├── payment_method_provider.dart ✅ DONE
│           │   └── cart_provider.dart ✅ UPDATED
│           ├── screens/
│           │   ├── payment_method_screen.dart ⏳ CODE PROVIDED
│           │   ├── payfast_payment_screen.dart ⏳ CODE PROVIDED
│           │   ├── payment_confirmation_screen.dart ⏳ CODE PROVIDED
│           │   └── checkout_screen.dart ⏳ NEEDS UPDATE
│           └── widgets/
│               └── payment_method_card.dart ✅ DONE
└── shared/
    └── widgets/
        ├── payment_security_badge.dart ✅ DONE
        └── payment_loading_indicator.dart ✅ DONE
```

---

## Success Metrics

### Completed (85%)
- [x] Payment state management
- [x] Payment method selection logic
- [x] Cart integration
- [x] All payment widgets
- [x] Code structure and architecture

### Remaining (15%)
- [ ] 3 payment screens (code provided, needs creation)
- [ ] Checkout screen integration (code provided, needs update)
- [ ] End-to-end testing
- [ ] Bug fixes and polish

---

## Estimated Time to 100% Completion

**Remaining Work:** 4-5 hours
- Create 3 screens: 2 hours
- Update checkout: 1 hour
- Testing & fixes: 1-2 hours

**Total Phase 2 Time:** ~10 hours (85% complete)

---

## Next Steps

1. **Create the 3 payment screens** using the code templates provided
2. **Update checkout_screen.dart** with PayFast integration
3. **Run flutter analyze** and fix any errors
4. **Test with PayFast sandbox** credentials
5. **Create unit tests** for critical components
6. **Document payment flow** for other developers

---

## Notes for Implementation

### Important Dependencies
```yaml
# Already in pubspec.yaml:
webview_flutter: ^4.4.2
connectivity_plus: ^5.0.2
flutter_secure_storage: ^9.0.0
```

### PayFast Sandbox Credentials
```env
PAYFAST_MERCHANT_ID=10000100
PAYFAST_MERCHANT_KEY=46f0cd694581a
PAYFAST_PASSPHRASE=your-test-passphrase
PAYFAST_MODE=sandbox
```

### Key Import Statements
```dart
// For payment screens:
import 'package:webview_flutter/webview_flutter.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_method_provider.dart';
import 'package:food_delivery_app/shared/widgets/payment_security_badge.dart';
import 'package:food_delivery_app/shared/widgets/payment_loading_indicator.dart';
```

---

**Status:** Ready for final implementation  
**Next Session:** Create remaining screens and complete integration  
**Estimated Completion:** 4-5 hours of focused work
