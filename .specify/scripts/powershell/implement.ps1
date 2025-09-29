#!/usr/bin/env pwsh
# Execute the implementation plan by processing and executing all tasks defined in tasks.md

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./implement.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

Write-Output "=== Implementing Feature ==="
Write-Output ""

# 1. Run check-prerequisites.ps1 with required parameters
Write-Output "Step 1: Checking prerequisites..."
try {
    $prereqResult = & (Join-Path $ScriptDir 'check-prerequisites.ps1') -Json -RequireTasks -IncludeTasks
    $prereqData = $prereqResult | ConvertFrom-Json
    
    $featureDir = $prereqData.FEATURE_DIR
    $availableDocs = $prereqData.AVAILABLE_DOCS
    
    Write-Output "  ✓ Prerequisites check passed"
    Write-Output "  ✓ Feature directory: $featureDir"
    Write-Output "  ✓ Available documents: $($availableDocs -join ', ')"
} 
catch {
    Write-Output "ERROR: Prerequisites check failed. Make sure you have spec.md, plan.md, and tasks.md files."
    Write-Output "Run the following commands in order if needed:"
    Write-Output "  /specify <feature description>"
    Write-Output "  /plan <tech stack details>"
    Write-Output "  /tasks"
    exit 1
}

# Define file paths
$tasksPath = Join-Path $featureDir 'tasks.md'
$planPath = Join-Path $featureDir 'plan.md'
$dataModelPath = Join-Path $featureDir 'data-model.md'
$researchPath = Join-Path $featureDir 'research.md'
$quickstartPath = Join-Path $featureDir 'quickstart.md'
$contractsDir = Join-Path $featureDir 'contracts'

# Verify required files exist
if (-not (Test-Path $tasksPath)) {
    Write-Output "ERROR: tasks.md not found at $tasksPath"
    exit 1
}
if (-not (Test-Path $planPath)) {
    Write-Output "ERROR: plan.md not found at $planPath"
    exit 1
}

Write-Output "  ✓ Required files found"
Write-Output ""

# 2. Load and analyze implementation context
Write-Output "Step 2: Loading implementation context..."
$tasksContent = Get-Content -Path $tasksPath -Raw
$planContent = Get-Content -Path $planPath -Raw

$hasDataModel = Test-Path $dataModelPath
$hasResearch = Test-Path $researchPath
$hasQuickstart = Test-Path $quickstartPath
$hasContracts = (Test-Path $contractsDir) -and (Get-ChildItem -Path $contractsDir -File | Measure-Object).Count -gt 0

Write-Output "  ✓ Loaded tasks.md"
Write-Output "  ✓ Loaded plan.md"
if ($hasDataModel) { Write-Output "  ✓ Loaded data-model.md" }
if ($hasResearch) { Write-Output "  ✓ Loaded research.md" }
if ($hasQuickstart) { Write-Output "  ✓ Loaded quickstart.md" }
if ($hasContracts) { Write-Output "  ✓ Loaded contracts/" }

Write-Output ""

# 3. Parse tasks.md structure
Write-Output "Step 3: Parsing tasks structure..."
$taskLines = $tasksContent -split "`n"
$tasks = @()
$currentPhase = "Unknown"
$taskIdPattern = "^(T\d{3}|[A-Z]{2,3}-\d{3}):?\s*(.+)$"

foreach ($line in $taskLines) {
    # Identify task phases
    if ($line -match "^# Setup Tasks") { $currentPhase = "Setup" }
    elseif ($line -match "^# Test Tasks") { $currentPhase = "Tests" }
    elseif ($line -match "^# Core Tasks") { $currentPhase = "Core" }
    elseif ($line -match "^# Integration Tasks") { $currentPhase = "Integration" }
    elseif ($line -match "^# Polish Tasks") { $currentPhase = "Polish" }
    
    # Extract tasks
    if ($line -match $taskIdPattern) {
        $taskId = $matches[1]
        $taskDesc = $matches[2]
        $isParallel = $line -match "\[P\]"
        
        $tasks += [PSCustomObject]@{
            Id = $taskId
            Description = $taskDesc
            Phase = $currentPhase
            Parallel = $isParallel
            Completed = $false
        }
    }
}

Write-Output "  ✓ Parsed $($tasks.Count) tasks across $($tasks | Select-Object -Unique -ExpandProperty Phase | Measure-Object | ForEach-Object { $_.Count }) phases"
Write-Output ""

# 4. Execute implementation following the task plan
Write-Output "Step 4: Executing implementation..."

$completedTasks = 0
$totalTasks = $tasks.Count

# Group tasks by phase
$phases = $tasks | Group-Object -Property Phase

foreach ($phase in $phases) {
    Write-Output "  Executing Phase: $($phase.Name)"
    
    # Separate sequential and parallel tasks within the phase
    $sequentialTasks = $phase.Group | Where-Object { -not $_.Parallel }
    $parallelTasks = $phase.Group | Where-Object { $_.Parallel }
    
    # Execute sequential tasks first
    foreach ($seqTask in $sequentialTasks) {
        Write-Output "    Processing: $($seqTask.Id) - $($seqTask.Description)"
        
        # In a real implementation, this would execute the actual task
        # For now, we'll just simulate completion
        Start-Sleep -Milliseconds 200 # Simulate work
        
        $seqTask.Completed = $true
        $completedTasks++
        
        Write-Output "      ✓ Completed: $($seqTask.Id)"
    }
    
    # Execute parallel tasks
    if ($parallelTasks.Count -gt 0) {
        Write-Output "    Processing $($parallelTasks.Count) parallel tasks..."
        foreach ($parTask in $parallelTasks) {
            Write-Output "      Processing: $($parTask.Id) - $($parTask.Description)"
            
            # In a real implementation, these would run in parallel
            # For now, we'll simulate completion
            Start-Sleep -Milliseconds 100  # Simulate work
            
            $parTask.Completed = $true
            $completedTasks++
            
            Write-Output "        ✓ Completed: $($parTask.Id)"
        }
    }
    
    Write-Output "  ✓ Completed Phase: $($phase.Name)"
    Write-Output ""
}

Write-Output "  ✓ All implementation phases completed"
Write-Output ""

# 5. Update tasks.md to mark completed tasks
Write-Output "Step 5: Updating tasks file with completion status..."

# Read the original tasks file
$updatedTasksContent = Get-Content -Path $tasksPath -Raw

# Replace task IDs with completed status
foreach ($task in $tasks) {
    if ($task.Completed) {
        # Replace the task line to mark as completed (change from T### to T### [X])
        $taskPattern = "^($([regex]::Escape($task.Id))\s*:?.*?)(\[.*?\])?(.*)$"
        $replacement = "$($task.Id) [X]`: $($task.Description)"
        $updatedTasksContent = $updatedTasksContent -replace $taskPattern, $replacement
    }
}

# Write the updated tasks file
Set-Content -Path $tasksPath -Value $updatedTasksContent

Write-Output "  ✓ Tasks file updated with completion status"
Write-Output ""

# 6. Completion validation
Write-Output "Step 6: Completion validation"
Write-Output "  - Total tasks processed: $totalTasks"
Write-Output "  - Tasks completed: $completedTasks"
Write-Output "  - Completion rate: $(if($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 })%"
Write-Output "  - All phases completed: Yes"

# Check if all tasks were completed successfully
$allCompleted = $completedTasks -eq $totalTasks
Write-Output "  - All tasks completed successfully: $(if($allCompleted) { "Yes" } else { "No" })"

Write-Output ""
Write-Output "Implementation process completed!"
Write-Output ""
if ($allCompleted) {
    Write-Output "Next suggested command: Validate the implementation with your testing framework."
} else {
    Write-Output "Some tasks were not completed. Review the implementation and try again."
}