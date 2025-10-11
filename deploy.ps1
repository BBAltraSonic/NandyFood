# NandyFood Deployment Script
# Simple version without special characters

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NandyFood Deployment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Project configuration
$PROJECT_REF = "[YOUR_SUPABASE_PROJECT_ID]"
$PAYSTACK_SECRET = "[YOUR_PAYSTACK_SECRET_KEY]"

Write-Host "Project Configuration:" -ForegroundColor Yellow
Write-Host "  Project ID: $PROJECT_REF"
Write-Host "  URL: https://$PROJECT_REF.supabase.co"
Write-Host ""

# Check Supabase CLI
Write-Host "[1/5] Checking Supabase CLI..." -ForegroundColor Yellow
$supabaseInstalled = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $supabaseInstalled) {
    Write-Host "ERROR: Supabase CLI not found!" -ForegroundColor Red
    Write-Host "Install: npm install -g supabase" -ForegroundColor Yellow
    Write-Host "Or visit: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
    exit 1
}
Write-Host "SUCCESS: Supabase CLI found" -ForegroundColor Green
Write-Host ""

# Link to project
Write-Host "[2/5] Linking to Supabase project..." -ForegroundColor Yellow
supabase link --project-ref $PROJECT_REF
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to link" -ForegroundColor Red
    Write-Host "Try: supabase login" -ForegroundColor Yellow
    exit 1
}
Write-Host "SUCCESS: Linked to project" -ForegroundColor Green
Write-Host ""

# Set secret key
Write-Host "[3/5] Setting Paystack secret key..." -ForegroundColor Yellow
supabase secrets set "PAYSTACK_SECRET_KEY=$PAYSTACK_SECRET"
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Failed to set secret (may need manual setup)" -ForegroundColor Yellow
} else {
    Write-Host "SUCCESS: Secret key configured" -ForegroundColor Green
}
Write-Host ""

# Deploy functions
Write-Host "[4/5] Deploying Edge Functions..." -ForegroundColor Yellow
Write-Host "  > Deploying initialize-paystack-payment..."
supabase functions deploy initialize-paystack-payment
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy initialize-paystack-payment" -ForegroundColor Red
} else {
    Write-Host "SUCCESS: initialize-paystack-payment deployed" -ForegroundColor Green
}

Write-Host "  > Deploying verify-paystack-payment..."
supabase functions deploy verify-paystack-payment
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy verify-paystack-payment" -ForegroundColor Red
} else {
    Write-Host "SUCCESS: verify-paystack-payment deployed" -ForegroundColor Green
}
Write-Host ""

# Apply migrations
Write-Host "[5/5] Applying database migrations..." -ForegroundColor Yellow
supabase db push
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Migration may have issues" -ForegroundColor Yellow
} else {
    Write-Host "SUCCESS: Migrations applied" -ForegroundColor Green
}
Write-Host ""

# Verify
Write-Host "Verifying deployment..." -ForegroundColor Yellow
supabase functions list
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Run: flutter run"
Write-Host "  2. Test card: 4084084084084081"
Write-Host "  3. Monitor: https://dashboard.paystack.com"
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  - QUICK_START.md"
Write-Host "  - DEPLOYMENT_READY.md"
Write-Host "  - PAYSTACK_READY.md"
Write-Host ""
