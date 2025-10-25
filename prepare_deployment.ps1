#!/usr/bin/env pwsh
# NandyFood - Deployment Preparation Script
# This script automates pre-deployment checks and preparations

param(
    [switch]$SkipTests,
    [switch]$SkipAnalyze,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$script:FailedSteps = @()
$script:Warnings = @()

# Colors for output
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host "  $Message" -ForegroundColor $Colors.Header
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor $Colors.Info
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Colors.Success
}

function Write-Failure {
    param([string]$Message, [string]$Step)
    Write-Host "✗ $Message" -ForegroundColor $Colors.Error
    $script:FailedSteps += $Step
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Colors.Warning
    $script:Warnings += $Message
}

function Test-FileExists {
    param([string]$Path, [string]$Description)

    if (Test-Path $Path) {
        Write-Success "$Description exists: $Path"
        return $true
    } else {
        Write-Failure "$Description not found: $Path" "File Check"
        return $false
    }
}

# Main script starts here
Clear-Host
Write-Header "NandyFood - Deployment Preparation"

$StartTime = Get-Date
$CurrentDir = Get-Location

Write-Host "Starting deployment preparation at: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $Colors.Info
Write-Host "Current directory: $CurrentDir" -ForegroundColor $Colors.Info
Write-Host ""

# ============================================
# Step 1: Environment Check
# ============================================
Write-Header "Step 1: Environment Check"

Write-Step "Checking Flutter installation..."
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Success "Flutter installed: $flutterVersion"
} catch {
    Write-Failure "Flutter not found in PATH" "Environment"
}

Write-Step "Checking Dart installation..."
try {
    $dartVersion = dart --version 2>&1
    Write-Success "Dart installed: $dartVersion"
} catch {
    Write-Failure "Dart not found in PATH" "Environment"
}

Write-Step "Checking required files..."
Test-FileExists "pubspec.yaml" "pubspec.yaml" | Out-Null
Test-FileExists ".env" ".env configuration" | Out-Null
Test-FileExists "lib\main.dart" "Main application file" | Out-Null
Test-FileExists "android\app\build.gradle" "Android build configuration" | Out-Null

if (Test-Path ".env.example") {
    Write-Success ".env.example template exists"
} else {
    Write-Warning ".env.example not found (recommended for documentation)"
}

# ============================================
# Step 2: Configuration Validation
# ============================================
Write-Header "Step 2: Configuration Validation"

Write-Step "Checking pubspec.yaml version..."
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml" -Raw
    if ($content -match "version:\s*(\d+\.\d+\.\d+\+\d+)") {
        $version = $Matches[1]
        Write-Success "App version: $version"
    } else {
        Write-Warning "Could not parse app version from pubspec.yaml"
    }
}

Write-Step "Checking environment configuration..."
if (Test-Path ".env") {
    Write-Success ".env file exists"
    Write-Warning "Remember to verify production credentials in .env"
} else {
    Write-Failure ".env file missing - create from .env.example" "Configuration"
}

Write-Step "Checking Firebase configuration..."
$firebaseAndroid = Test-FileExists "android\app\google-services.json" "Firebase Android config"
if ($firebaseAndroid) {
    Write-Warning "Verify google-services.json is for PRODUCTION Firebase project"
}

if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    Write-Success "Firebase iOS config exists"
    Write-Warning "Verify GoogleService-Info.plist is for PRODUCTION Firebase project"
} else {
    Write-Warning "Firebase iOS config not found (iOS build will fail)"
}

# ============================================
# Step 3: Database Migration Check
# ============================================
Write-Header "Step 3: Database Migration Check"

Write-Step "Checking migration files..."
$migrationFile = "database\migrations\20241201_add_new_features.sql"
$verifyFile = "supabase\migrations\verify_all_tables.sql"

if (Test-Path $migrationFile) {
    $fileSize = (Get-Item $migrationFile).Length
    Write-Success "Migration file exists: $migrationFile ($([math]::Round($fileSize/1KB, 2)) KB)"
} else {
    Write-Failure "Migration file not found: $migrationFile" "Database"
}

if (Test-Path $verifyFile) {
    Write-Success "Verification script exists: $verifyFile"
} else {
    Write-Warning "Verification script not found: $verifyFile"
}

Write-Host ""
Write-Host "⚠ IMPORTANT: Database migration must be applied manually:" -ForegroundColor $Colors.Warning
Write-Host "  1. Open Supabase Dashboard → SQL Editor" -ForegroundColor White
Write-Host "  2. Copy contents of: $migrationFile" -ForegroundColor White
Write-Host "  3. Paste and click 'Run'" -ForegroundColor White
Write-Host "  4. Verify with: $verifyFile" -ForegroundColor White

# ============================================
# Step 4: Clean and Get Dependencies
# ============================================
Write-Header "Step 4: Clean and Get Dependencies"

Write-Step "Cleaning project..."
try {
    flutter clean 2>&1 | Out-Null
    Write-Success "Project cleaned successfully"
} catch {
    Write-Failure "Failed to clean project: $_" "Clean"
}

Write-Step "Getting dependencies (this may take a minute)..."
try {
    $output = flutter pub get 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies fetched successfully"

        # Check for outdated packages
        $outdatedCount = ($output | Select-String "available" | Measure-Object).Count
        if ($outdatedCount -gt 0) {
            Write-Warning "$outdatedCount packages have newer versions available"
            Write-Host "  Run 'flutter pub outdated' for details" -ForegroundColor Gray
        }
    } else {
        Write-Failure "Failed to fetch dependencies" "Dependencies"
    }
} catch {
    Write-Failure "Error fetching dependencies: $_" "Dependencies"
}

# ============================================
# Step 5: Code Analysis
# ============================================
if (-not $SkipAnalyze) {
    Write-Header "Step 5: Code Analysis"

    Write-Step "Running Flutter analyzer (this may take a minute)..."
    try {
        $analyzeOutput = flutter analyze 2>&1 | Out-String

        if ($analyzeOutput -match "No issues found!") {
            Write-Success "Code analysis passed with no issues"
        } elseif ($analyzeOutput -match "(\d+) issue.*found") {
            $issueCount = $Matches[1]

            # Check if they're all info-level
            if ($analyzeOutput -notmatch "error -") {
                Write-Warning "Found $issueCount info/warning level issues (non-blocking)"
                Write-Host "  These are style/lint warnings and won't prevent deployment" -ForegroundColor Gray
            } else {
                Write-Failure "Found $issueCount issues including errors" "Analysis"
                Write-Host "  Run 'flutter analyze' for details" -ForegroundColor Gray
            }
        } else {
            Write-Warning "Could not parse analysis results"
        }

        # Check for specific error patterns
        if ($analyzeOutput -match "error -") {
            Write-Failure "Code contains errors that must be fixed" "Analysis"
        }

    } catch {
        Write-Failure "Failed to run analyzer: $_" "Analysis"
    }
} else {
    Write-Warning "Skipping code analysis (--SkipAnalyze flag used)"
}

# ============================================
# Step 6: Run Tests
# ============================================
if (-not $SkipTests) {
    Write-Header "Step 6: Run Tests"

    Write-Step "Running all tests (this may take a few minutes)..."
    try {
        $testOutput = flutter test 2>&1 | Out-String

        if ($testOutput -match "All tests passed!") {
            Write-Success "All tests passed successfully"
        } elseif ($testOutput -match "(\d+) passed") {
            $passedTests = $Matches[1]

            if ($testOutput -match "(\d+) failed") {
                $failedTests = $Matches[1]
                Write-Failure "$failedTests test(s) failed out of $passedTests total" "Tests"
            } else {
                Write-Success "$passedTests test(s) passed"
            }
        } else {
            Write-Warning "Could not parse test results"
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "Tests failed - fix before deployment" "Tests"
        }

    } catch {
        Write-Failure "Failed to run tests: $_" "Tests"
    }
} else {
    Write-Warning "Skipping tests (--SkipTests flag used)"
}

# ============================================
# Step 7: Build Check (Dry Run)
# ============================================
Write-Header "Step 7: Build Validation"

Write-Step "Validating build configuration..."

# Check Android signing
if (Test-Path "android\key.properties") {
    Write-Success "Android signing configuration exists"
} else {
    Write-Warning "android\key.properties not found - production build will fail"
    Write-Host "  Create key.properties with keystore configuration" -ForegroundColor Gray
}

# Check for keystore
if (Test-Path "android\app\*.keystore") {
    Write-Success "Android keystore found"
} else {
    Write-Warning "Android keystore not found in android\app\"
    Write-Host "  Generate keystore: keytool -genkey -v -keystore release.keystore -alias release" -ForegroundColor Gray
}

Write-Step "Checking if project can build (debug mode)..."
Write-Host "  Note: Not building release to save time. Will validate configuration only." -ForegroundColor Gray

# ============================================
# Step 8: Asset Check
# ============================================
Write-Header "Step 8: Asset Validation"

Write-Step "Checking required assets..."

$assetDirs = @(
    "assets\images",
    "assets\icons",
    "assets\branding",
    "assets\animations"
)

foreach ($dir in $assetDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -File).Count
        Write-Success "$dir exists ($fileCount files)"
    } else {
        Write-Warning "$dir not found (may be optional)"
    }
}

# Check fonts
if (Test-Path "assets\fonts") {
    $fontFiles = Get-ChildItem "assets\fonts" -Filter "*.ttf"
    if ($fontFiles.Count -gt 0) {
        Write-Success "Found $($fontFiles.Count) font file(s)"
    } else {
        Write-Warning "No font files found in assets\fonts"
    }
} else {
    Write-Warning "assets\fonts directory not found"
}

# ============================================
# Step 9: Documentation Check
# ============================================
Write-Header "Step 9: Documentation Check"

$requiredDocs = @{
    "README.md" = "Project overview"
    "DEPLOYMENT_GUIDE.md" = "Deployment instructions"
    "DEPLOYMENT_READINESS.md" = "Pre-deployment checklist"
}

$missingDocs = @()
foreach ($doc in $requiredDocs.GetEnumerator()) {
    if (Test-Path $doc.Key) {
        Write-Success "$($doc.Value): $($doc.Key)"
    } else {
        Write-Warning "$($doc.Value) not found: $($doc.Key)"
        $missingDocs += $doc.Key
    }
}

# Check for legal documents
Write-Step "Checking legal documentation..."
$legalFiles = @("PRIVACY_POLICY.md", "TERMS_OF_SERVICE.md", "privacy_policy.html", "terms.html")
$legalFound = $false
foreach ($file in $legalFiles) {
    if (Test-Path $file) {
        Write-Success "Legal document found: $file"
        $legalFound = $true
    }
}

if (-not $legalFound) {
    Write-Warning "No privacy policy or terms of service found (REQUIRED for app stores)"
    Write-Host "  Create these before submitting to stores" -ForegroundColor Gray
}

# ============================================
# Step 10: Summary and Next Steps
# ============================================
Write-Header "Deployment Preparation Summary"

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

Write-Host "Preparation completed in $([math]::Round($Duration.TotalSeconds, 2)) seconds" -ForegroundColor $Colors.Info
Write-Host ""

# Summary statistics
if ($script:FailedSteps.Count -eq 0) {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Success
    Write-Host "  ✓ ALL CRITICAL CHECKS PASSED" -ForegroundColor $Colors.Success
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Success
    Write-Host ""
} else {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Error
    Write-Host "  ✗ FAILED CHECKS: $($script:FailedSteps.Count)" -ForegroundColor $Colors.Error
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Error
    Write-Host ""
    Write-Host "Failed steps:" -ForegroundColor $Colors.Error
    foreach ($step in $script:FailedSteps) {
        Write-Host "  - $step" -ForegroundColor $Colors.Error
    }
    Write-Host ""
}

if ($script:Warnings.Count -gt 0) {
    Write-Host "⚠ WARNINGS: $($script:Warnings.Count)" -ForegroundColor $Colors.Warning
    Write-Host "Review warnings above - some may be critical for production" -ForegroundColor $Colors.Warning
    Write-Host ""
}

# Next steps
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Info
Write-Host "  NEXT STEPS" -ForegroundColor $Colors.Info
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Info
Write-Host ""

Write-Host "1. Apply Database Migration:" -ForegroundColor White
Write-Host "   - Open Supabase Dashboard → SQL Editor" -ForegroundColor Gray
Write-Host "   - Run: database\migrations\20241201_add_new_features.sql" -ForegroundColor Gray
Write-Host "   - Verify with: supabase\migrations\verify_all_tables.sql" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Verify Environment Configuration:" -ForegroundColor White
Write-Host "   - Check .env has production credentials" -ForegroundColor Gray
Write-Host "   - Verify Firebase projects are production" -ForegroundColor Gray
Write-Host "   - Confirm payment gateway settings" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Create Legal Documents (if missing):" -ForegroundColor White
Write-Host "   - Privacy Policy (REQUIRED)" -ForegroundColor Gray
Write-Host "   - Terms of Service (REQUIRED)" -ForegroundColor Gray
Write-Host "   - Host on public URLs" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Build Release Versions:" -ForegroundColor White
Write-Host "   Android: flutter build appbundle --release" -ForegroundColor Gray
Write-Host "   iOS:     flutter build ipa --release" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Prepare App Store Listings:" -ForegroundColor White
Write-Host "   - Screenshots (all device sizes)" -ForegroundColor Gray
Write-Host "   - App descriptions" -ForegroundColor Gray
Write-Host "   - Feature graphics" -ForegroundColor Gray
Write-Host "   - Privacy Policy URLs" -ForegroundColor Gray
Write-Host ""

Write-Host "6. Submit for Review:" -ForegroundColor White
Write-Host "   - Google Play Console" -ForegroundColor Gray
Write-Host "   - Apple App Store Connect" -ForegroundColor Gray
Write-Host ""

Write-Host "7. Monitor Post-Launch:" -ForegroundColor White
Write-Host "   - Firebase Crashlytics" -ForegroundColor Gray
Write-Host "   - Supabase Dashboard" -ForegroundColor Gray
Write-Host "   - App Store metrics" -ForegroundColor Gray
Write-Host ""

# Final recommendation
if ($script:FailedSteps.Count -eq 0 -and $script:Warnings.Count -lt 5) {
    Write-Host "✓ Project is READY for deployment preparation!" -ForegroundColor $Colors.Success
    Write-Host "  Complete the next steps above to deploy to production." -ForegroundColor $Colors.Success
} elseif ($script:FailedSteps.Count -eq 0) {
    Write-Host "⚠ Project is MOSTLY READY but has warnings to review" -ForegroundColor $Colors.Warning
    Write-Host "  Fix warnings before production deployment." -ForegroundColor $Colors.Warning
} else {
    Write-Host "✗ Project is NOT READY for deployment" -ForegroundColor $Colors.Error
    Write-Host "  Fix failed checks before proceeding." -ForegroundColor $Colors.Error
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $Colors.Info
Write-Host ""

# Create summary file
$summaryFile = "deployment_preparation_summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$summaryContent = @"
NandyFood - Deployment Preparation Summary
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

CHECKS PERFORMED:
- Environment validation
- Configuration check
- Database migration validation
- Dependencies updated
- Code analysis $(if ($SkipAnalyze) { "(SKIPPED)" } else { "" })
- Tests $(if ($SkipTests) { "(SKIPPED)" } else { "" })
- Build validation
- Asset check
- Documentation review

RESULTS:
- Failed Checks: $($script:FailedSteps.Count)
- Warnings: $($script:Warnings.Count)
- Duration: $([math]::Round($Duration.TotalSeconds, 2)) seconds

STATUS: $(if ($script:FailedSteps.Count -eq 0) { "READY" } else { "NOT READY" })

FAILED STEPS:
$($script:FailedSteps | ForEach-Object { "- $_" } | Out-String)

WARNINGS:
$($script:Warnings | ForEach-Object { "- $_" } | Out-String)

For full deployment guide, see: DEPLOYMENT_GUIDE.md
For readiness checklist, see: DEPLOYMENT_READINESS.md
"@

$summaryContent | Out-File -FilePath $summaryFile -Encoding UTF8
Write-Host "Summary saved to: $summaryFile" -ForegroundColor $Colors.Info

exit $script:FailedSteps.Count
