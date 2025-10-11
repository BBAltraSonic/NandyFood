# NandyFood Deployment Setup Script
# Run this script to deploy all Supabase functions and test the app

Write-Host "🚀 NandyFood Deployment Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
Write-Host "📋 Checking Supabase CLI..." -ForegroundColor Yellow
$supabaseInstalled = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseInstalled) {
    Write-Host "❌ Supabase CLI not found!" -ForegroundColor Red
    Write-Host "Install it from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
    Write-Host "Or run: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Supabase CLI found" -ForegroundColor Green
Write-Host ""

# Project details
$PROJECT_REF = "[YOUR_SUPABASE_PROJECT_ID]"
$PAYSTACK_SECRET = "[YOUR_PAYSTACK_SECRET_KEY]"

Write-Host "📦 Project Configuration:" -ForegroundColor Cyan
Write-Host "  Project: $PROJECT_REF" -ForegroundColor White
Write-Host "  URL: https://$PROJECT_REF.supabase.co" -ForegroundColor White
Write-Host ""

# Step 1: Link to Supabase project
Write-Host "🔗 Step 1: Linking to Supabase project..." -ForegroundColor Yellow
supabase link --project-ref $PROJECT_REF
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to link to Supabase project" -ForegroundColor Red
    Write-Host "Please login first: supabase login" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Linked to project" -ForegroundColor Green
Write-Host ""

# Step 2: Set Paystack secret key
Write-Host "🔑 Step 2: Setting Paystack secret key..." -ForegroundColor Yellow
supabase secrets set "PAYSTACK_SECRET_KEY=$PAYSTACK_SECRET"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Failed to set secret key (you may need to do this manually)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Secret key configured" -ForegroundColor Green
}
Write-Host ""

# Step 3: Deploy Edge Functions
Write-Host "☁️  Step 3: Deploying Edge Functions..." -ForegroundColor Yellow

Write-Host "  Deploying initialize-paystack-payment..." -ForegroundColor White
supabase functions deploy initialize-paystack-payment
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to deploy initialize-paystack-payment" -ForegroundColor Red
} else {
    Write-Host "✅ initialize-paystack-payment deployed" -ForegroundColor Green
}

Write-Host "  Deploying verify-paystack-payment..." -ForegroundColor White
supabase functions deploy verify-paystack-payment
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to deploy verify-paystack-payment" -ForegroundColor Red
} else {
    Write-Host "✅ verify-paystack-payment deployed" -ForegroundColor Green
}
Write-Host ""

# Step 4: Apply database migrations
Write-Host "🗄️  Step 4: Applying database migrations..." -ForegroundColor Yellow
supabase db push
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Migration may have failed - check manually if needed" -ForegroundColor Yellow
} else {
    Write-Host "✅ Migrations applied" -ForegroundColor Green
}
Write-Host ""

# Step 5: Verify deployment
Write-Host "✅ Step 5: Verifying deployment..." -ForegroundColor Yellow
supabase functions list
Write-Host ""

# Summary
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Run your app: flutter run" -ForegroundColor White
Write-Host "  2. Test payment with card: 4084084084084081" -ForegroundColor White
Write-Host "  3. Monitor transactions: https://dashboard.paystack.com" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  - DEPLOYMENT_READY.md" -ForegroundColor White
Write-Host "  - PAYSTACK_READY.md" -ForegroundColor White
Write-Host "  - PAYSTACK_MIGRATION_GUIDE.md" -ForegroundColor White
Write-Host ""
Write-Host "Need help? Check the documentation files above!" -ForegroundColor Yellow
Write-Host ""
