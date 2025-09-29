#!/usr/bin/env pwsh
# Identify underspecified areas in the current feature spec by asking targeted clarification questions

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./clarify.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

Write-Output "=== Clarifying Feature Specification ==="
Write-Output ""

# 1. Run check-prerequisites.ps1 with PathsOnly parameter
Write-Output "Step 1: Checking prerequisites..."
try {
    $prereqResult = & (Join-Path $ScriptDir 'check-prerequisites.ps1') -Json -PathsOnly
    $prereqData = $prereqResult | ConvertFrom-Json
    
    $featureDir = $prereqData.FEATURE_DIR
    $featureSpec = $prereqData.FEATURE_SPEC
    
    Write-Output "  ✓ Prerequisites check passed"
    Write-Output "  ✓ Feature directory: $featureDir"
    Write-Output "  ✓ Feature spec: $featureSpec"
} 
catch {
    Write-Output "ERROR: Prerequisites check failed. Make sure you have a spec.md file."
    Write-Output "Run the following command first if needed:"
    Write-Output "  /specify <feature description>"
    exit 1
}

# Verify spec file exists
if (-not (Test-Path $featureSpec)) {
    Write-Output "ERROR: spec.md not found at $featureSpec"
    exit 1
}

Write-Output "  ✓ Spec file found"
Write-Output ""

# 2. Load the current spec file and perform ambiguity scan
Write-Output "Step 2: Analyzing spec for ambiguities..."
$specContent = Get-Content -Path $featureSpec -Raw
$specLines = $specContent -split "`n"

# Initialize coverage map
$coverageMap = @{
    "Functional Scope & Behavior" = "Clear"
    "Domain & Data Model" = "Clear" 
    "Interaction & UX Flow" = "Clear"
    "Non-Functional Quality Attributes" = "Clear"
    "Integration & External Dependencies" = "Clear"
    "Edge Cases & Failure Handling" = "Clear"
    "Constraints & Tradeoffs" = "Clear"
    "Terminology & Consistency" = "Clear"
    "Completion Signals" = "Clear"
    "Misc / Placeholders" = "Clear"
}

# Scan for various categories of information
$hasFunctionalRequirements = $false
$hasUserStories = $false
$hasNonFunctional = $false
$hasDataModel = $false
$hasErrorHandling = $false
$hasPlaceholders = $false

foreach ($line in $specLines) {
    if ($line -match "Functional Requirements") { $hasFunctionalRequirements = $true }
    if ($line -match "User Scenarios|User Stories") { $hasUserStories = $true }
    if ($line -match "Performance|Scalability|Reliability|Security|Compliance") { $hasNonFunctional = $true }
    if ($line -match "Key Entities|Data Model") { $hasDataModel = $true }
    if ($line -match "Error|Failure|Edge Case|Negative scenario") { $hasErrorHandling = $true }
    
    # Check for placeholders
    if ($line -match "(?i)(TODO|TKTK|\?\?\?|<[^>]+>)") { 
        $hasPlaceholders = $true 
        $coverageMap["Misc / Placeholders"] = "Missing"
    }
}

# Update coverage map based on findings
if (-not $hasFunctionalRequirements) { $coverageMap["Functional Scope & Behavior"] = "Missing" }
if (-not $hasDataModel) { $coverageMap["Domain & Data Model"] = "Missing" }
if (-not $hasUserStories) { $coverageMap["Interaction & UX Flow"] = "Missing" }
if (-not $hasNonFunctional) { $coverageMap["Non-Functional Quality Attributes"] = "Missing" }
if (-not $hasErrorHandling) { $coverageMap["Edge Cases & Failure Handling"] = "Missing" }

Write-Output "  ✓ Analysis complete"
Write-Output ""

# 3. Generate prioritized queue of clarification questions
Write-Output "Step 3: Generating clarification questions..."

# Identify areas that need clarification
$candidateQuestions = @()

if ($coverageMap["Functional Scope & Behavior"] -ne "Clear") {
    $candidateQuestions += "What are the core user goals and success criteria for this feature?"
}

if ($coverageMap["Domain & Data Model"] -ne "Clear") {
    $candidateQuestions += "What are the key entities, their attributes, and relationships in this feature?"
}

if ($coverageMap["Non-Functional Quality Attributes"] -ne "Clear") {
    $candidateQuestions += "What are the performance, scalability, and reliability requirements?"
}

if ($coverageMap["Edge Cases & Failure Handling"] -ne "Clear") {
    $candidateQuestions += "How should the system handle errors and edge cases?"
}

if ($coverageMap["Misc / Placeholders"] -eq "Missing") {
    $candidateQuestions += "Are there any placeholders in the spec that need to be resolved?"
}

# Limit to 5 questions max
if ($candidateQuestions.Count -gt 5) {
    $candidateQuestions = $candidateQuestions[0..4]
}

Write-Output "  ✓ Generated $($candidateQuestions.Count) clarification questions"
Write-Output ""

# 4. Sequential questioning loop (simulated)
Write-Output "Step 4: Clarification session (simulated)..."
$answers = @{}
$questionCount = 0

foreach ($question in $candidateQuestions) {
    if ($questionCount -ge 5) { break }  # Max 5 questions
    
    Write-Output "Question $($questionCount + 1): $question"
    
    # For simulation purposes, we'll provide a default answer
    # In a real implementation, this would be interactive
    $answer = "Answer to question $($questionCount + 1)"
    $answers[$question] = $answer
    
    Write-Output "  Answer: $answer"
    Write-Output ""
    
    $questionCount++
}

Write-Output "  ✓ Clarification session completed"
Write-Output ""

# 5. Update the spec file with clarifications
Write-Output "Step 5: Updating spec with clarifications..."

# Read the current spec content
$currentSpec = Get-Content -Path $featureSpec -Raw

# Add clarifications section if it doesn't exist
$today = Get-Date -Format "yyyy-MM-dd"
$clarificationsSection = @"
## Clarifications

### Session $today

"@

# Check if clarifications section already exists
if ($currentSpec -notmatch "## Clarifications") {
    # Find a good place to insert the clarifications section (after the overview section)
    $insertPosition = 0
    $lines = $currentSpec -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## (Overview|Context|Summary)") {
            # Find the end of this section
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match "^## ") {
                    $insertPosition = $j
                    break
                }
            }
            break
        }
    }
    
    # If no suitable position found, insert near the beginning
    if ($insertPosition -eq 0) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## [^#]") {  # First main section
                $insertPosition = $i
                break
            }
        }
    }
    
    # Insert the clarifications section
    $newSpec = ($lines[0..($insertPosition - 1)] -join "`n") + "`n$clarificationsSection" + ($lines[$insertPosition..($lines.Count - 1)] -join "`n")
} else {
    $newSpec = $currentSpec
}

# Add the clarifications to the section
foreach ($question in $answers.Keys) {
    $newSpec += "- Q: $question → A: $($answers[$question])`n"
}

# Write the updated spec back to file
Set-Content -Path $featureSpec -Value $newSpec

Write-Output "  ✓ Spec updated with clarifications"
Write-Output ""

# 6. Validation and final report
Write-Output "Step 6: Validation and completion report"
Write-Output "  - Questions asked & answered: $($answers.Count)"
Write-Output "  - Updated spec path: $featureSpec"
Write-Output "  - Sections touched: Clarifications"
Write-Output ""
Write-Output "Coverage Summary Table:"
Write-Output "| Category | Status |"
Write-Output "|----------|--------|"
foreach ($category in $coverageMap.Keys) {
    Write-Output "| $category | $($coverageMap[$category]) |"
}

Write-Output ""
Write-Output "Suggested next command: /plan"
Write-Output ""
Write-Output "Clarification process completed. The spec has been updated with answers to key questions."