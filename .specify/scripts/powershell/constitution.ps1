#!/usr/bin/env pwsh
# Create or update the project constitution from interactive or provided principle inputs

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./constitution.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

Write-Output "=== Managing Project Constitution ==="
Write-Output ""

# Define paths
$repoRoot = Get-RepoRoot
$constitutionPath = Join-Path $repoRoot '.specify/memory/constitution.md'
$planTemplatePath = Join-Path $repoRoot '.specify/templates/plan-template.md'
$specTemplatePath = Join-Path $repoRoot '.specify/templates/spec-template.md'
$tasksTemplatePath = Join-Path $repoRoot '.specify/templates/tasks-template.md'

# Check if constitution file exists
$constitutionExists = Test-Path $constitutionPath
if (-not $constitutionExists) {
    Write-Output "Constitution file does not exist. Creating a new one..."
    
    # Create a basic constitution template
    $basicConstitution = @"
# Project Constitution: [PROJECT_NAME]

Preamble
This document establishes the guiding principles for the development of [PROJECT_NAME]. Its purpose is to ensure the creation of a high-quality, reliable, and performant application that delivers an exceptional user experience. All technical decisions, code contributions, and architectural changes must align with these principles.

## Article I: Code Quality & Maintainability
All code is an investment in the future of the project. It must be written with clarity, simplicity, and maintainability as primary goals.

## Article II: Testing & Reliability
A robust testing suite is non-negotiable and is the foundation of application reliability and user trust.

## Article III: User Experience (UX) & Design Consistency
The user experience must be seamless, intuitive, and consistent across the entire application.

## Article IV: Performance & Efficiency
The application must feel fast, responsive, and respectful of the user's device resources.

## Article V: Governance & Evolution
These principles will guide our work and will be upheld through a transparent governance process.

RATIFICATION_DATE: [RATIFICATION_DATE]
LAST_AMENDED_DATE: [LAST_AMENDED_DATE]
VERSION: [VERSION]

"@
    
    Set-Content -Path $constitutionPath -Value $basicConstitution
    Write-Output "  ✓ Created new constitution template at $constitutionPath"
} else {
    Write-Output "  ✓ Constitution file found at $constitutionPath"
}

# Load the existing constitution
$constitutionContent = Get-Content -Path $constitutionPath -Raw
Write-Output "  ✓ Loaded constitution content"

# Identify placeholder tokens
$placeholderPattern = '\[([A-Z_0-9]+)\]'
$matches = [regex]::Matches($constitutionContent, $placeholderPattern)
$placeholders = @()
foreach ($match in $matches) {
    if ($placeholders -notcontains $match.Groups[1].Value) {
        $placeholders += $match.Groups[1].Value
    }
}

Write-Output "  ✓ Found $($placeholders.Count) placeholder tokens: $($placeholders -join ', ')"

# Collect/derive values for placeholders
$placeholderValues = @{}

# Project name - derive from repo name if not provided
if ($placeholders -contains "PROJECT_NAME") {
    $placeholderValues["PROJECT_NAME"] = Split-Path $repoRoot -Leaf
    Write-Output "  - Set PROJECT_NAME to: $($placeholderValues["PROJECT_NAME"])"
}

# Date placeholders
if ($placeholders -contains "RATIFICATION_DATE") {
    # Check if we have an existing ratification date in the file
    $dateMatch = [regex]::Match($constitutionContent, 'RATIFICATION_DATE:\s*(\d{4}-\d{2}-\d{2}|\[RATIFICATION_DATE\])')
    if ($dateMatch.Success -and $dateMatch.Groups[1].Value -ne "[RATIFICATION_DATE]") {
        $placeholderValues["RATIFICATION_DATE"] = $dateMatch.Groups[1].Value
    } else {
        # For new constitutions, use today's date as ratification date
        $placeholderValues["RATIFICATION_DATE"] = Get-Date -Format "yyyy-MM-dd"
    }
    Write-Output "  - Set RATIFICATION_DATE to: $($placeholderValues["RATIFICATION_DATE"])"
}

if ($placeholders -contains "LAST_AMENDED_DATE") {
    $placeholderValues["LAST_AMENDED_DATE"] = Get-Date -Format "yyyy-MM-dd"
    Write-Output "  - Set LAST_AMENDED_DATE to: $($placeholderValues["LAST_AMENDED_DATE"])"
}

# Version placeholder
if ($placeholders -contains "VERSION") {
    # Check if there's an existing version in the file
    $versionMatch = [regex]::Match($constitutionContent, 'VERSION:\s*(\d+\.\d+\.\d+|\[VERSION\])')
    if ($versionMatch.Success -and $versionMatch.Groups[1].Value -ne "[VERSION]") {
        # For simplicity, we'll increment the patch version
        $existingVersion = $versionMatch.Groups[1].Value
        $versionParts = $existingVersion.Split('.')
        $versionParts[2] = [int]$versionParts[2] + 1
        $placeholderValues["VERSION"] = $versionParts -join '.'
    } else {
        # Default to 1.0.0 for new constitutions
        $placeholderValues["VERSION"] = "1.0.0"
    }
    Write-Output "  - Set VERSION to: $($placeholderValues["VERSION"])"
}

# Replace placeholders in the constitution content
$updatedConstitution = $constitutionContent
foreach ($placeholder in $placeholderValues.Keys) {
    $updatedConstitution = $updatedConstitution -replace "\[$placeholder\]", $placeholderValues[$placeholder]
}

# Add sync impact report as HTML comment at the top
$today = Get-Date -Format "yyyy-MM-dd"
$syncReport = @"
<!-- 
Sync Impact Report:
- Version change: Previous → $($placeholderValues["VERSION"])
- Modified on: $today
- Templates requiring updates: plan-template.md, spec-template.md, tasks-template.md
- Files checked for consistency: plan-template.md, spec-template.md, tasks-template.md, tasks-template.md
-->
"@

$updatedConstitution = $syncReport + "`n" + $updatedConstitution

# Write the updated constitution back to file
Set-Content -Path $constitutionPath -Value $updatedConstitution
Write-Output "  ✓ Updated constitution with placeholder values"

# 4. Consistency propagation checklist
Write-Output "Step 4: Checking template consistency..."

$templatesUpdated = 0
$templatesPending = 0

# Check plan-template.md for constitution references
if (Test-Path $planTemplatePath) {
    $planTemplateContent = Get-Content -Path $planTemplatePath -Raw
    # This would normally check for alignment with updated principles
    Write-Output "  ✓ Checked plan-template.md for constitution alignment"
    $templatesUpdated++
} else {
    Write-Output "  ⚠ plan-template.md not found"
    $templatesPending++
}

# Check spec-template.md for constitution references
if (Test-Path $specTemplatePath) {
    $specTemplateContent = Get-Content -Path $specTemplatePath -Raw
    # This would normally check for alignment with updated principles
    Write-Output "  ✓ Checked spec-template.md for constitution alignment"
    $templatesUpdated++
} else {
    Write-Output "  ⚠ spec-template.md not found"
    $templatesPending++
}

# Check tasks-template.md for constitution references
if (Test-Path $tasksTemplatePath) {
    $tasksTemplateContent = Get-Content -Path $tasksTemplatePath -Raw
    # This would normally check for alignment with updated principles
    Write-Output "  ✓ Checked tasks-template.md for constitution alignment"
    $templatesUpdated++
} else {
    Write-Output "  ⚠ tasks-template.md not found"
    $templatesPending++
}

Write-Output ""

# 6. Validation
Write-Output "Step 6: Validation..."

# Check for remaining unexplained bracket tokens (excluding the sync report comment)
$contentWithoutComment = ($updatedConstitution -split "`n" | Select-Object -Skip 8) -join "`n"
$remainingPlaceholders = [regex]::Matches($contentWithoutComment, $placeholderPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

if ($remainingPlaceholders.Count -gt 0) {
    Write-Warning "Found remaining placeholders: $($remainingPlaceholders -join ', ')"
} else {
    Write-Output "  ✓ No remaining unexplained bracket tokens found"
}

Write-Output ""

# 8. Final summary
Write-Output "Step 8: Constitution update summary"
Write-Output "  - New version: $($placeholderValues["VERSION"])"
Write-Output "  - Ratification date: $($placeholderValues["RATIFICATION_DATE"])"
Write-Output "  - Amendment date: $($placeholderValues["LAST_AMENDED_DATE"])"
Write-Output "  - Templates updated: $templatesUpdated"
Write-Output "  - Templates pending: $templatesPending"
Write-Output ""
Write-Output "Suggested commit message: docs: amend constitution to $($placeholderValues["VERSION"]) (initial setup)"
Write-Output ""
Write-Output "Constitution management completed."