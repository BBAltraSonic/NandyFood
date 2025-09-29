#!/usr/bin/env pwsh
# Minimal analysis script for debugging purposes

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./minimal_analyze.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir '.specify/scripts/powershell/common.ps1')

Write-Output "=== Analyzing Project Artifacts (Minimal Version) ==="
Write-Output ""

# Run check-prerequisites.ps1 with required parameters
Write-Output "Step 1: Checking prerequisites..."
try {
    $checkPrereqScript = Join-Path $ScriptDir '.specify/scripts/powershell/check-prerequisites.ps1'
    $prereqResult = & $checkPrereqScript -Json -RequireTasks -IncludeTasks
    $prereqData = $prereqResult | ConvertFrom-Json
    
    $featureDir = $prereqData.FEATURE_DIR
    $availableDocs = $prereqData.AVAILABLE_DOCS
    
    Write-Output "  [Prerequisites check passed]"
    Write-Output "  [Feature directory: $featureDir]"
    Write-Output "  [Available documents: $($availableDocs -join ', ')]"
} 
catch {
    Write-Output "ERROR: Prerequisites check failed. Make sure you have spec.md, plan.md, and tasks.md files."
    Write-Output "Run the following commands in order if needed:"
    Write-Output "  /specify ``<feature description>``"
    Write-Output "  /plan ``<tech stack details>``"
    Write-Output "  /tasks"
    exit 1
}

# Define file paths
$specPath = Join-Path $featureDir 'spec.md'
$planPath = Join-Path $featureDir 'plan.md'
$tasksPath = Join-Path $featureDir 'tasks.md'
$constitutionPath = Join-Path (Get-RepoRoot) '.specify/memory/constitution.md'

# Verify all required files exist
if (-not (Test-Path $specPath)) {
    Write-Output "ERROR: spec.md not found at $specPath"
    exit 1
}
if (-not (Test-Path $planPath)) {
    Write-Output "ERROR: plan.md not found at $planPath"
    exit 1
}
if (-not (Test-Path $tasksPath)) {
    Write-Output "ERROR: tasks.md not found at $tasksPath"
    exit 1
}
if (-not (Test-Path $constitutionPath)) {
    Write-Output "ERROR: constitution.md not found at $constitutionPath"
    exit 1
}

Write-Output "  ✓ All required files found"
Write-Output ""

# Load artifacts
Write-Output "Step 2: Loading artifacts..."
$specContent = Get-Content -Path $specPath -Raw
$planContent = Get-Content -Path $planPath -Raw
$tasksContent = Get-Content -Path $tasksPath -Raw
$constitutionContent = Get-Content -Path $constitutionPath -Raw

Write-Output "  ✓ Loaded spec.md"
Write-Output "  ✓ Loaded plan.md" 
Write-Output "  ✓ Loaded tasks.md"
Write-Output "  ✓ Loaded constitution.md"
Write-Output ""

# Build internal semantic models - basic version without complex text processing
Write-Output "Step 3: Building basic semantic models..."
$requirements = @()
$stories = @()
$tasks = @()
$constitutions = @()

# Extract functional requirements from spec.md
$specLines = $specContent -split "`n"
$inFunctionalRequirements = $false
$inNonFunctionalRequirements = $false
$inUserScenarios = $false

foreach ($line in $specLines) {
    if ($line -match "^### Functional Requirements") {
        $inFunctionalRequirements = $true
        continue
    }
    if ($line -match "^### Non-Functional Requirements") {
        $inFunctionalRequirements = $false
        $inNonFunctionalRequirements = $true
        continue
    }
    if ($line -match "^### User Scenarios" -or $line -match "^### User Stories") {
        $inFunctionalRequirements = $false
        $inNonFunctionalRequirements = $false
        $inUserScenarios = $true
        continue
    }
    
    if ($inFunctionalRequirements -or $inNonFunctionalRequirements) {
        $regexPattern = '^\s*-\s*\*\*([A-Z]{2,3}-\d{3})\*\*:?\s*(.+)'
        if ($line -match $regexPattern) {
            $reqId = $matches[1]
            $reqText = $matches[2]
            $requirements += [PSCustomObject]@{
                Id = $reqId
                Text = $reqText
                Type = if ($inFunctionalRequirements) { "Functional" } else { "Non-Functional" }
                Source = "spec.md"
            }
        }
    }
    
    if ($inUserScenarios) {
        if ($line -match "^###? Acceptance Scenarios") {
            $inUserScenarios = $false
            continue
        }
        if ($line -match "^(\d+)\.\s*\*\*Given\*\*.*\*\*When\*\*.*\*\*Then\*\*") {
            $stories += [PSCustomObject]@{
                Id = "STORY-$($matches[1])"
                Text = $line.Trim()
                Source = "spec.md"
            }
        }
        elseif ($line -match "^-\s*What happens when.*\?") {
            # Edge cases
            $stories += [PSCustomObject]@{
                Id = "EDGE-CASE-$($stories.Count + 1)"
                Text = $line.Trim()
                Source = "spec.md"
            }
        }
    }
}

# Extract tasks from tasks.md
$taskLines = $tasksContent -split "`n"
$taskIdPattern = '^(T\d{3}|[A-Z]{2,3}-\d{3}):?\s*(.+)$'
$taskNumber = 1

foreach ($line in $taskLines) {
    if ($line -match $taskIdPattern) {
        $taskId = $matches[1]
        $taskText = $matches[2]
        $isParallel = $line -match "\[P\]"
        
        $tasks += [PSCustomObject]@{
            Id = $taskId
            Text = $taskText
            Parallel = $isParallel
            Source = "tasks.md"
        }
        $taskNumber++
    }
}

# Extract constitution principles
$constitutionLines = $constitutionContent -split "`n"
$inArticle = $false
$articleName = ""

foreach ($line in $constitutionLines) {
    if ($line -match "^Article [IVX]+:" -or $line -match "^# [A-Z]") {
        $inArticle = $true
        $articleName = ($line -split ":")[0] -replace "^#+\s*", ""
        continue
    }
    
    if ($inArticle) {
        if ($line -match "MUST|MUST NOT|SHOULD|SHOULD NOT") {
            $constitutions += [PSCustomObject]@{
                Article = $articleName
                Text = $line.Trim()
                Source = "constitution.md"
            }
        }
    }
}

Write-Output "  ✓ Extracted $($requirements.Count) requirements"
Write-Output "  ✓ Extracted $($stories.Count) user stories/scenarios"
Write-Output "  ✓ Extracted $($tasks.Count) tasks"
Write-Output "  ✓ Extracted $($constitutions.Count) constitutional principles"
Write-Output ""

# Basic analysis without the complex text similarity calculations
Write-Output "Step 4: Running basic analysis..."
$findings = @()

# Simple placeholder check
Write-Output "  A. Checking for placeholders..."
$placeholderPattern = "(?i)(TODO|TKTK|\?\?\?|<[^>]+>)"
foreach ($artifact in @($specContent, $planContent, $tasksContent)) {
    $regexMatches = [regex]::Matches($artifact, $placeholderPattern)
    foreach ($match in $regexMatches) {
        $findings += [PSCustomObject]@{
            Id = "A" + ($findings.Count + 1)
            Category = "Ambiguity"
            Severity = "HIGH"
            Location = "Multiple files"
            Summary = "Unresolved placeholder found: $($match.Value)"
            Details = "Placeholder '$($match.Value)' needs resolution"
            Recommendation = "Replace with actual content"
        }
    }
}

Write-Output "  ✓ Basic analysis completed"
Write-Output ""

# Generate basic report
Write-Output "Step 5: Generating basic analysis report..."
Write-Output ""
Write-Output "# Basic Specification Analysis Report"
Write-Output ""
Write-Output "## Findings"
foreach ($finding in $findings) {
    Write-Output "- $($finding.Severity): $($finding.Summary)"
    Write-Output "  Location: $($finding.Location)"
    Write-Output "  Recommendation: $($finding.Recommendation)"
    Write-Output ""
}

Write-Output "## Metrics:"
Write-Output "* Total Requirements: $($requirements.Count)"
Write-Output "* Total Tasks: $($tasks.Count)"
Write-Output "* Total User Stories: $($stories.Count)"
Write-Output "* Issues Found: $($findings.Count)"