# =====================================================
# NandyFood - Supabase Setup Script
# =====================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NandyFood - Supabase Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with your Supabase credentials." -ForegroundColor Yellow
    exit 1
}

# Extract Supabase credentials from .env
$envContent = Get-Content ".env" -Raw
$supabaseUrl = ""
$supabaseKey = ""

if ($envContent -match "SUPABASE_URL=(.+)") {
    $supabaseUrl = $matches[1].Trim()
}

if ($envContent -match "SUPABASE_ANON_KEY=(.+)") {
    $supabaseKey = $matches[1].Trim()
}

if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-Host "ERROR: Could not extract Supabase credentials from .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "Success: Found Supabase credentials" -ForegroundColor Green
Write-Host "  URL: $supabaseUrl" -ForegroundColor Gray
Write-Host ""

# List of migrations in order
$migrations = @(
    "001 - User Profiles",
    "002 - Addresses",
    "003 - Restaurants",
    "004 - Menu Items",
    "005 - Orders",
    "006 - Deliveries and Promotions",
    "007 - Row Level Security",
    "007b - Paystack Payment Methods",
    "008 - Storage Buckets"
)

Write-Host "Found $($migrations.Count) migrations to apply" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
$supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabaseCli) {
    Write-Host "Warning: Supabase CLI is not installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You have two options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Install Supabase CLI (Recommended)" -ForegroundColor Green
    Write-Host "  Run: scoop install supabase" -ForegroundColor Gray
    Write-Host "  Or visit: https://supabase.com/docs/guides/cli" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Apply migrations manually" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://supabase.com/dashboard/project/brelcfytcagdtfkhbkaf/editor" -ForegroundColor Gray
    Write-Host "  2. Open each migration file in the supabase\migrations folder" -ForegroundColor Gray
    Write-Host "  3. Copy the SQL and execute it in the SQL Editor" -ForegroundColor Gray
    Write-Host "  4. Apply migrations in numerical order (001, 002, 003, etc.)" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Would you like to see the migration files list? (Y/N)"
    if ($choice -eq "Y" -or $choice -eq "y") {
        Write-Host ""
        Write-Host "Migration files:" -ForegroundColor Cyan
        foreach ($migration in $migrations) {
            Write-Host "  - $migration" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "Success: Supabase CLI found" -ForegroundColor Green
    Write-Host ""
    Write-Host "To apply all migrations, run:" -ForegroundColor Cyan
    Write-Host "  supabase db push" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or to link your local project to Supabase:" -ForegroundColor Cyan
    Write-Host "  supabase link --project-ref brelcfytcagdtfkhbkaf" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Apply database migrations (see instructions above)" -ForegroundColor White
Write-Host "2. Deploy Edge Functions for Paystack payments" -ForegroundColor White
Write-Host "3. Set up storage buckets (included in migrations)" -ForegroundColor White
Write-Host "4. Test database connection with Flutter app" -ForegroundColor White
Write-Host ""
Write-Host "For more details, see: SUPABASE_SETUP_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
