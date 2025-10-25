# Quick Fix Script for Riverpod 3.x Provider Compatibility
# This script adds the legacy import to all files using StateNotifierProvider

Write-Host "🔧 Fixing Riverpod 3.x Provider Compatibility..." -ForegroundColor Cyan

$files = @(
    "lib\core\providers\auth_provider.dart",
    "lib\core\providers\base_provider.dart",
    "lib\core\providers\restaurant_session_provider.dart",
    "lib\core\providers\role_provider.dart",
    "lib\core\providers\theme_provider.dart",
    "lib\features\authentication\presentation\providers\user_provider.dart",
    "lib\features\delivery\presentation\providers\delivery_orders_provider.dart",
    "lib\features\favourites\presentation\providers\favourites_provider.dart",
    "lib\features\onboarding\providers\onboarding_provider.dart",
    "lib\features\order\presentation\providers\add_item_provider.dart",
    "lib\features\order\presentation\providers\cart_provider.dart",
    "lib\features\order\presentation\providers\driver_location_provider.dart",
    "lib\features\order\presentation\providers\order_provider.dart",
    "lib\features\order\presentation\providers\order_tracking_provider.dart",
    "lib\features\order\presentation\providers\payment_method_provider.dart",
    "lib\features\order\presentation\providers\payment_provider.dart",
    "lib\features\order\presentation\providers\place_order_provider.dart",
    "lib\features\order\presentation\providers\promotion_provider.dart",
    "lib\features\profile\presentation\providers\address_provider.dart",
    "lib\features\profile\presentation\providers\payment_methods_provider.dart",
    "lib\features\profile\presentation\providers\profile_provider.dart",
    "lib\features\restaurant\presentation\providers\restaurant_provider.dart",
    "lib\features\restaurant\presentation\providers\review_provider.dart",
    "lib\features\restaurant_dashboard\presentation\providers\analytics_provider.dart",
    "lib\features\restaurant_dashboard\providers\restaurant_dashboard_provider.dart"
)

$legacyImport = "import 'package:flutter_riverpod/flutter_riverpod.dart' hide StateNotifierProvider;`nimport 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod show StateNotifierProvider;"
$oldImport = "import 'package:flutter_riverpod/flutter_riverpod.dart';"

$fixedCount = 0
$errorCount = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        try {
            $content = Get-Content $file -Raw
            
            # Check if file uses StateNotifierProvider
            if ($content -match "StateNotifierProvider") {
                # Check if already has the fix
                if ($content -notmatch "hide StateNotifierProvider") {
                    Write-Host "  ✓ Fixing: $file" -ForegroundColor Green
                    
                    # Replace the import
                    $content = $content -replace [regex]::Escape($oldImport), $legacyImport
                    
                    # Update StateNotifierProvider references to use riverpod prefix
                    $content = $content -replace '(?<!riverpod\.)StateNotifierProvider', 'riverpod.StateNotifierProvider'
                    
                    Set-Content $file -Value $content -NoNewline
                    $fixedCount++
                } else {
                    Write-Host "  → Already fixed: $file" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  - Skipped (no StateNotifierProvider): $file" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  ✗ Error fixing: $file" -ForegroundColor Red
            Write-Host "    $_" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  ! File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Fixed: $fixedCount files" -ForegroundColor Green
Write-Host "  Errors: $errorCount files" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })

Write-Host "`n✅ Riverpod provider compatibility fix complete!" -ForegroundColor Green
Write-Host "   Run 'flutter analyze' to verify" -ForegroundColor Cyan
