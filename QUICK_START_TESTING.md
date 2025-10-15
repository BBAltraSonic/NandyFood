# Quick Start: Testing PayFast Integration

## 🚀 Ready to Test!

All code is implemented and ready for testing. Follow these steps to test the PayFast payment integration.

---

## Step 1: Configure Sandbox Credentials

Create a `.env` file (copy from `.env.example`):

```bash
cd C:\Users\BB\Documents\NandyFood
copy .env.example .env
```

Edit `.env` with PayFast sandbox credentials:

```env
# PayFast Sandbox Credentials (for testing)
PAYFAST_MERCHANT_ID=10000100
PAYFAST_MERCHANT_KEY=46f0cd694581a
PAYFAST_PASSPHRASE=test_passphrase
PAYFAST_MODE=sandbox

# URLs (will be configured for sandbox)
PAYFAST_RETURN_URL=https://nandyfood.com/payment/success
PAYFAST_CANCEL_URL=https://nandyfood.com/payment/cancel
PAYFAST_NOTIFY_URL=https://nandyfood.com/api/payment/webhook
```

---

## Step 2: Apply Database Migration

Apply the PayFast migration to your Supabase database:

**Option 1: Supabase Dashboard**
1. Go to https://app.supabase.com
2. Select your project
3. Go to SQL Editor
4. Copy contents of `supabase/migrations/015_payfast_integration.sql`
5. Run the SQL

**Option 2: Supabase CLI**
```bash
cd C:\Users\BB\Documents\NandyFood
supabase db push
```

---

## Step 3: Run the App

```bash
cd C:\Users\BB\Documents\NandyFood
flutter run
```

---

## Step 4: Test Payment Flows

### Test 1: Cash Payment (Baseline)
1. Add items to cart
2. Go to checkout
3. Tap on "Payment Method"
4. Select "Cash on Delivery"
5. Go back to checkout
6. Tap "Place Order"
7. ✅ Verify order confirmation appears

### Test 2: PayFast Payment (Success)
1. Add items to cart
2. Go to checkout
3. Tap on "Payment Method"
4. Select "Card Payment (PayFast)"
5. Go back to checkout
6. Tap "Place Order"
7. Wait for "Initializing secure payment..."
8. PayFast page loads in WebView
9. Enter test card details (see sandbox test cards below)
10. Complete payment
11. ✅ Verify success screen with order details

### Test 3: Payment Cancellation
1. Start PayFast payment (steps 1-8 from Test 2)
2. Press back button (X)
3. Confirm cancellation in dialog
4. ✅ Verify return to checkout with "Payment cancelled" message

### Test 4: Payment Failure
1. Start PayFast payment
2. Enter invalid card details
3. ✅ Verify failure screen with retry options

---

## PayFast Sandbox Test Cards

### Success Card
- **Card Number:** 4000 0000 0000 0002
- **Expiry:** Any future date (e.g., 12/25)
- **CVV:** Any 3 digits (e.g., 123)

### Declined Card
- **Card Number:** 4000 0000 0000 0127
- **Expiry:** Any future date
- **CVV:** Any 3 digits

---

## Verification Checklist

After testing, verify:

### Database
- [ ] Check `payment_transactions` table for new records
- [ ] Verify transaction status is 'completed' for successful payments
- [ ] Check `payment_webhook_logs` table for webhook entries

### App Behavior
- [ ] Loading indicators appear during payment
- [ ] Security badges visible on payment screens
- [ ] Success screen shows order details
- [ ] Failure screen shows error message
- [ ] Cancel returns to checkout
- [ ] Payment method selector works
- [ ] Icons display correctly (cash/card)

### Logs
Check AppLogger output for:
- [ ] Payment initialization logged
- [ ] Signature generation logged
- [ ] WebView navigation logged
- [ ] Payment response processing logged
- [ ] No errors in payment flow

---

## Troubleshooting

### "No internet connection" error
- Check device/emulator has internet
- Verify connectivity service is working
- Check firewall settings

### PayFast page doesn't load
- Verify `.env` file has correct credentials
- Check `PAYFAST_MODE=sandbox`
- Ensure WebView permissions granted
- Check AppLogger for error messages

### Payment hangs on "Processing"
- Check webhook URL is accessible
- Verify signature generation is correct
- Review AppLogger for errors
- Check Supabase connection

### Database errors
- Ensure migration was applied
- Check RLS policies are enabled
- Verify user authentication
- Review Supabase logs

---

## View Logs

To see detailed logs while testing:

```bash
# Run with verbose logging
flutter run -v

# Or filter for payment logs
flutter run | findstr "Payment"
```

Look for these log patterns:
- `🔵 ENTER → PaymentService.initializePayment`
- `✅ SUCCESS: Payment initialized`
- `🔴 EXIT ← PaymentService.processPaymentResponse`
- `⏱️  PERFORMANCE: Payment initialization took Xms`

---

## Production Deployment

Once testing is successful:

1. **Update Environment**
   ```env
   PAYFAST_MODE=live
   PAYFAST_MERCHANT_ID=<your-live-id>
   PAYFAST_MERCHANT_KEY=<your-live-key>
   PAYFAST_PASSPHRASE=<strong-passphrase>
   ```

2. **Configure Webhook**
   - Set up Supabase Edge Function for webhook endpoint
   - Update `PAYFAST_NOTIFY_URL` with production URL
   - Test webhook with PayFast

3. **Final Checks**
   - [ ] SSL certificate pinning enabled
   - [ ] Error monitoring active (Sentry/Crashlytics)
   - [ ] Payment notification emails configured
   - [ ] Support team trained
   - [ ] User documentation created

---

## Support Resources

### Documentation
- Implementation: `FINAL_COMPLETION_REPORT.md`
- Code Templates: `PHASE2_COMPLETION_STATUS.md`
- Architecture: `PHASE1_2_IMPLEMENTATION_SUMMARY.md`

### PayFast Resources
- Developer Docs: https://developers.payfast.co.za/docs
- Sandbox: https://sandbox.payfast.co.za/
- Support: support@payfast.co.za

### Debugging
- Check AppLogger output for detailed traces
- Review Supabase logs for database errors
- Check Flutter DevTools for UI issues
- Review `payment_webhook_logs` table for webhook debugging

---

## Quick Command Reference

```bash
# Run app
flutter run

# Run with logs
flutter run -v

# Check for errors
flutter analyze --no-fatal-infos

# Rebuild
flutter clean && flutter pub get

# Generate models
dart run build_runner build --delete-conflicting-outputs

# View logs (Windows)
flutter logs

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal
```

---

## Test Scenarios Summary

| Test | Payment Method | Expected Result | Status |
|------|----------------|-----------------|--------|
| 1 | Cash on Delivery | Order placed successfully | [ ] |
| 2 | PayFast Success | Payment processed, order placed | [ ] |
| 3 | PayFast Cancel | Return to checkout | [ ] |
| 4 | PayFast Failure | Error message with retry | [ ] |
| 5 | Network Error | Friendly error message | [ ] |

---

**Ready to test! 🎉**

Start with Test 1 (Cash) to verify baseline functionality, then proceed to PayFast tests.

Good luck with testing!
