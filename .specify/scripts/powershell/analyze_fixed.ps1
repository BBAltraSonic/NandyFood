#!/usr/bin/env pwsh
# Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./analyze.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

Write-Output "=== Analyzing Project Artifacts ==="
Write-Output ""

# 1. Run check-prerequisites.ps1 with required parameters
Write-Output "Step 1: Checking prerequisites..."
try {
    $checkPrereqScript = Join-Path $ScriptDir 'check-prerequisites.ps1'
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

# 2. Load artifacts
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

# 3. Build internal semantic models
Write-Output "Step 3: Building semantic models..."
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

# 4. Detection passes
Write-Output "Step 4: Running detection passes..."
$findings = @()

# A. Duplication detection
Write-Output "  A. Checking for duplications..."
foreach ($req1 in $requirements) {
    foreach ($req2 in $requirements) {
        if ($req1.Id -ne $req2.Id) {
            $similarity = Calculate-TextSimilarity -Text1 $req1.Text -Text2 $req2.Text
            if ($similarity -gt 0.8) {  # 80% similarity threshold
                $findings += [PSCustomObject]@{
                    Id = "A" + ($findings.Count + 1)
                    Category = "Duplication"
                    Severity = "HIGH"
                    Location = "$($req1.Source), $($req2.Source)"
                    Summary = "Highly similar requirements found"
                    Details = "$($req1.Id): $($req1.Text) and $($req2.Id): $($req2.Text)"
                    Recommendation = "Consider consolidating these similar requirements"
                }
            }
        }
    }
}

# B. Ambiguity detection
Write-Output "  B. Checking for ambiguities..."
$ambiguousTerms = @("fast", "scalable", "secure", "intuitive", "robust", "efficient", "user-friendly", "high-performance")
foreach ($req in $requirements) {
    foreach ($term in $ambiguousTerms) {
        if ($req.Text -match "\b$term\b") {
            $findings += [PSCustomObject]@{
                Id = "B" + ($findings.Count + 1)
                Category = "Ambiguity"
                Severity = "HIGH"
                Location = $req.Source
                Summary = "Ambiguous term '$term' found in requirement"
                Details = "$($req.Id): $($req.Text)"
                Recommendation = "Replace with measurable criteria for example 'secure' to 'encrypted with AES-256'"
            }
        }
    }
}

# Check for placeholders
$placeholderPattern = "(?i)(TODO|TKTK|\?\?\?|<[^>]+>)"
foreach ($artifact in @($specContent, $planContent, $tasksContent)) {
    $regexMatches = [regex]::Matches($artifact, $placeholderPattern)
    foreach ($match in $regexMatches) {
        $findings += [PSCustomObject]@{
            Id = "B" + ($findings.Count + 1)
            Category = "Ambiguity"
            Severity = "HIGH"
            Location = "Multiple files"
            Summary = "Unresolved placeholder found: $($match.Value)"
            Details = "Placeholder '$($match.Value)' needs resolution"
            Recommendation = "Replace with actual content"
        }
    }
}

# C. Underspecification
Write-Output "  C. Checking for underspecification..."
foreach ($req in $requirements) {
    # Check for requirements with verbs but missing measurable outcome
    $hasKeyword = ($req.Text -match "should") -or ($req.Text -match "must") -or ($req.Text -match "will")
    $hasAction = ($req.Text -match "perform") -or ($req.Text -match "execute") -or ($req.Text -match "handle") -or ($req.Text -match "manage")
    $hasMeasure = ($req.Text -match "within") -or ($req.Text -match "less than") -or ($req.Text -match "more than") -or ($req.Text -match "at least") -or ($req.Text -match "at most") -or ($req.Text -match "by") -or ($req.Text -match "in") -or ($req.Text -match "during") -or ($req.Text -match "for") -or ($req.Text -match "after")
    if ($hasKeyword -and $hasAction -and -not $hasMeasure) {
        $findings += [PSCustomObject]@{
            Id = "C" + ($findings.Count + 1)
            Category = "Underspecification"
            Severity = "MEDIUM"
            Location = $req.Source
            Summary = "Requirement lacks measurable outcome"
            Details = "$($req.Id): $($req.Text)"
            Recommendation = "Add measurable criteria like time, quantity, quality, etc."
        }
    }
}

# D. Constitution alignment
Write-Output "  D. Checking constitution alignment..."
foreach ($req in $requirements) {
    # Check for conflicts with constitutional principles
    foreach ($const in $constitutions) {
        # This is a simplified check - in a real implementation, this would be more sophisticated
        if ($const.Text -match "MUST NOT" -and $req.Text -match "MUST NOT") {
            $findings += [PSCustomObject]@{
                Id = "D" + ($findings.Count + 1)
                Category = "Constitution Alignment"
                Severity = "CRITICAL"
                Location = "constitution.md, $req.Source"
                Summary = "Potential constitutional conflict"
                Details = "Requirement '$($req.Text)' may conflict with constitutional principle '$($const.Text)'"
                Recommendation = "Review and resolve conflict with constitutional principle"
            }
        }
    }
}

# E. Coverage gaps
Write-Output "  E. Checking for coverage gaps..."
foreach ($req in $requirements) {
    $hasTask = $false
    foreach ($task in $tasks) {
        # Simple text matching to see if task covers requirement
        if ($task.Text -match [regex]::Escape($req.Text.Substring(0, [Math]::Min(10, $req.Text.Length)))) {
            $hasTask = $true
            break
        }
    }
    
    if (-not $hasTask) {
        $findings += [PSCustomObject]@{
            Id = "E" + ($findings.Count + 1)
            Category = "Coverage Gap"
            Severity = "HIGH"
            Location = "$($req.Source), tasks.md"
            Summary = "Requirement has no associated task"
            Details = "Requirement $($req.Id) '$($req.Text)' has no corresponding task"
            Recommendation = "Create tasks to implement this requirement"
        }
    }
}

# F. Inconsistency
Write-Output "  F. Checking for inconsistencies..."
# Check for terminology differences between spec and plan
$specTerms = $specContent -split '\W+' | Where-Object { $_.Length -gt 4 } | Group-Object | Sort-Object Count -Descending | Select-Object -First 20 -ExpandProperty Name
$planTerms = $planContent -split '\W+' | Where-Object { $_.Length -gt 4 } | Group-Object | Sort-Object Count -Descending | Select-Object -First 20 -ExpandProperty Name

$diffTerms = Compare-Object -ReferenceObject $specTerms -DifferenceObject $planTerms
if ($diffTerms.Count -gt 0) {
    $findings += [PSCustomObject]@{
        Id = "F" + ($findings.Count + 1)
        Category = "Inconsistency"
        Severity = "MEDIUM"
        Location = "spec.md, plan.md"
        Summary = "Terminology differences between spec and plan"
        Details = "Different terms used in spec vs plan: $($diffTerms.InputObject -join ', ')"
        Recommendation = "Standardize terminology across documents"
    }
}

Write-Output "  ✓ Detection passes completed"
Write-Output ""

# 5. Severity assignment and report generation
Write-Output "Step 5: Generating analysis report..."
Write-Output ""
Write-Output "# Specification Analysis Report"
Write-Output ""
$pipe = [char]124  # ASCII code for pipe character
$dash = [char]45   # ASCII code for dash character
$tableHeader1 = "${pipe} ID ${pipe} Category ${pipe} Severity ${pipe} Location(s) ${pipe} Summary ${pipe} Recommendation ${pipe}"
$tableHeader2 = "${pipe}${dash}${dash}${dash}${dash}${pipe}${dash}${dash}${pipe}${dash}${dash}${dash}${dash}${pipe}${dash}${dash}${pipe}${dash}${dash}${dash}${dash}${pipe}${dash}${dash}${pipe}"
Write-Output $tableHeader1
Write-Output $tableHeader2

foreach ($finding in $findings) {
    $pipe = [char]124  # ASCII code for pipe character
    Write-Output("${pipe} " + $finding.Id + " ${pipe} " + $finding.Category + " ${pipe} " + $finding.Severity + " ${pipe} " + $finding.Location + " ${pipe} " + $finding.Summary + " ${pipe} " + $finding.Recommendation + " ${pipe}")
}

Write-Output ""
Write-Output "## Coverage Summary Table"
$pipe = [char]124  # ASCII code for pipe character
$dash = [char]45   # ASCII code for dash character
$coverageHeader1 = "${pipe} Requirement Key ${pipe} Has Task? ${pipe} Task IDs ${pipe} Notes ${pipe}"
$coverageHeader2 = "${pipe}${dash}${dash}${dash}${pipe}${dash}${dash}${dash}${pipe}${dash}${dash}${pipe}${dash}${dash}${pipe}"
Write-Output $coverageHeader1
Write-Output $coverageHeader2

$reqCoverage = @()
foreach ($req in $requirements) {
    $hasTask = $false
    $taskIds = @()
    
    foreach ($task in $tasks) {
        if ($task.Text -match [regex]::Escape($req.Text.Substring(0, [Math]::Min(10, $req.Text.Length)))) {
            $hasTask = $true
            $taskIds += $task.Id
        }
    }
    
    $reqCoverage += [PSCustomObject]@{
        ReqId = $req.Id
        HasTask = if ($hasTask) { "Yes" } else { "No" }
        TaskIds = $taskIds -join ", "
        Notes = if (-not $hasTask) { "Missing coverage" } else { "" }
    }
}

foreach ($coverage in $reqCoverage) {
    $pipe = [char]124  # ASCII code for pipe character
    Write-Output("${pipe} " + $coverage.ReqId + " ${pipe} " + $coverage.HasTask + " ${pipe} " + $coverage.TaskIds + " ${pipe} " + $coverage.Notes + " ${pipe}")
}

Write-Output ""
Write-Output "## Constitution Alignment Issues"
$constIssues = $findings | Where-Object { $_.Category -eq "Constitution Alignment" }
if ($constIssues.Count -gt 0) {
    foreach ($constIssue in $constIssues) {
        Write-Output "- $($constIssue.Details)"
    }
} else {
    Write-Output "No constitution alignment issues found."
}

Write-Output ""
Write-Output "## Unmapped Tasks"
$unmappedTasks = @()
foreach ($task in $tasks) {
    $hasReq = $false
    foreach ($req in $requirements) {
        if ($task.Text -match [regex]::Escape($req.Text.Substring(0, [Math]::Min(10, $req.Text.Length)))) {
            $hasReq = $true
            break
        }
    }
    
    if (-not $hasReq) {
        $unmappedTasks += $task
    }
}

if ($unmappedTasks.Count -gt 0) {
    foreach ($unmappedTask in $unmappedTasks) {
        Write-Output "- $($unmappedTask.Id): $($unmappedTask.Text)"
    }
} else {
    Write-Output "No unmapped tasks found."
}

Write-Output ""
Write-Output "## Metrics:"
Write-Output "* Total Requirements: $($requirements.Count)"
Write-Output "* Total Tasks: $($tasks.Count)"
Write-Output "* Coverage %: $(if($requirements.Count -gt 0) { [math]::Round((($requirements.Count - $reqCoverage | Where-Object {$_.HasTask -eq 'No'}).Count) / $requirements.Count * 100, 2) } else { 0 })%"
Write-Output "* Ambiguity Count: $(($findings | Where-Object {$_.Category -eq 'Ambiguity'}).Count)"
Write-Output "* Duplication Count: $(($findings | Where-Object {$_.Category -eq 'Duplication'}).Count)"
Write-Output "* Critical Issues Count: $(($findings | Where-Object {$_.Severity -eq 'CRITICAL'}).Count)"

Write-Output ""
Write-Output "## Next Actions"
$criticalIssues = $findings | Where-Object { $_.Severity -eq "CRITICAL" }
if ($criticalIssues.Count -gt 0) {
    Write-Output "CRITICAL issues detected. Recommend resolving before implementation:"
    foreach ($crit in $criticalIssues) {
        Write-Output "- $($crit.Summary)"
    }
    Write-Output ""
    Write-Output "Suggested commands:"
    Write-Output "- Review and update spec.md to resolve conflicts"
    Write-Output "- Run /plan to adjust architecture if needed"
    Write-Output "- Update tasks.md to align with resolved requirements"
} else {
    Write-Output "No CRITICAL issues found. Implementation can proceed, but consider addressing MEDIUM and LOW issues."
    Write-Output ""
    Write-Output "Suggested commands:"
    Write-Output "- Review and address HIGH severity issues before implementation"
    Write-Output "- Run /analyze again after making changes to verify resolution"
}

Write-Output ""
Write-Output "Would you like me to suggest concrete remediation edits for the top issues?"

# Helper function for text similarity (simplified)
function Calculate-TextSimilarity {
    param(
        [string]$Text1,
        [string]$Text2
    )
    
    # Simple word overlap approach
    $words1 = $Text1.ToLower() -split '\W+' | Where-Object { $_.Length -gt 3 }
    $words2 = $Text2.ToLower() -split '\W+' | Where-Object { $_.Length -gt 3 }
    
    $commonWords = $words1 | Where-Object { $words2 -contains $_ } | Measure-Object
    $totalWords = ($words1 + $words2) | Sort-Object -Unique | Measure-Object
    
    if ($totalWords.Count -eq 0) { return 0 }
    
    return [double]$commonWords.Count / [double]$totalWords.Count
}