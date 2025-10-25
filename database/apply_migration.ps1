# ============================================
# NandyFood Database Migration Script
# Description: Apply database migrations to Supabase
# ============================================

param(
    [Parameter(Mandatory=$false)]
    [string]$MigrationFile = "migrations\20241201_add_new_features.sql",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header {
    param([string]$Message)
    Write-ColorOutput Yellow ""
    Write-ColorOutput Yellow "========================================="
    Write-ColorOutput Yellow $Message
    Write-ColorOutput Yellow "========================================="
    Write-ColorOutput Yellow ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput Green "✓ $Message"
}

function Write-Error-Message {
    param([string]$Message)
    Write-ColorOutput Red "✗ $Message"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput Cyan "ℹ $Message"
}

function Write-Warning-Message {
    param([string]$Message)
    Write-ColorOutput Yellow "⚠ $Message"
}

# ============================================
# Main Script
# ============================================

Write-Header "NandyFood Database Migration Tool"

# Check if .env file exists
$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Error-Message ".env file not found!"
    Write-Info "Please create a .env file with SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY"
    exit 1
}

Write-Info "Loading environment variables from .env..."

# Load environment variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
        if ($Verbose) {
            Write-Info "Loaded: $key"
        }
    }
}

# Get Supabase credentials
$supabaseUrl = [Environment]::GetEnvironmentVariable("SUPABASE_URL", "Process")
$supabaseKey = [Environment]::GetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY", "Process")

if (-not $supabaseUrl) {
    $supabaseKey = [Environment]::GetEnvironmentVariable("SUPABASE_ANON_KEY", "Process")
}

if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-Error-Message "Missing Supabase credentials!"
    Write-Info "Required environment variables:"
    Write-Info "  - SUPABASE_URL"
    Write-Info "  - SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY)"
    exit 1
}

Write-Success "Environment variables loaded"
Write-Info "Supabase URL: $supabaseUrl"

# Check if migration file exists
$migrationPath = Join-Path $PSScriptRoot $MigrationFile

if (-not (Test-Path $migrationPath)) {
    Write-Error-Message "Migration file not found: $migrationPath"
    exit 1
}

Write-Success "Migration file found: $MigrationFile"

# Read migration SQL
$migrationSql = Get-Content $migrationPath -Raw
Write-Info "Migration file size: $($migrationSql.Length) bytes"

# Dry run mode
if ($DryRun) {
    Write-Warning-Message "DRY RUN MODE - No changes will be applied"
    Write-Info ""
    Write-Info "Migration SQL Preview:"
    Write-Info "----------------------------------------"
    Write-ColorOutput White ($migrationSql.Substring(0, [Math]::Min(500, $migrationSql.Length)))
    if ($migrationSql.Length -gt 500) {
        Write-Info "... (truncated, showing first 500 characters)"
    }
    Write-Info "----------------------------------------"
    Write-Info ""
    Write-Warning-Message "To apply this migration, run without -DryRun flag"
    exit 0
}

# Confirm before applying
Write-Warning-Message "You are about to apply database migration!"
Write-Info "Migration: $MigrationFile"
Write-Info "Database: $supabaseUrl"
Write-Info ""
$confirmation = Read-Host "Type 'YES' to continue or anything else to cancel"

if ($confirmation -ne "YES") {
    Write-Warning-Message "Migration cancelled by user"
    exit 0
}

Write-Info ""
Write-Header "Applying Migration..."

# Note: Direct SQL execution via REST API requires the SQL Editor API or pgAdmin
# For Supabase, we'll use the REST API with a stored procedure approach

Write-Info "Connecting to Supabase..."

# Check if psql is available (PostgreSQL client)
$psqlAvailable = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlAvailable) {
    Write-Info "Using psql (PostgreSQL client)"

    # Extract database connection details from Supabase URL
    if ($supabaseUrl -match 'https://([^.]+)\.supabase\.co') {
        $projectRef = $matches[1]
        $dbHost = "db.$projectRef.supabase.co"
        $dbPort = 5432
        $dbName = "postgres"

        Write-Info "Database host: $dbHost"

        # Prompt for database password
        Write-Info "Please enter your database password (from Supabase dashboard):"
        $dbPassword = Read-Host -AsSecureString
        $dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword)
        )

        # Set PGPASSWORD environment variable
        $env:PGPASSWORD = $dbPasswordPlain

        try {
            # Execute migration using psql
            $psqlCommand = "psql -h $dbHost -p $dbPort -U postgres -d $dbName -f `"$migrationPath`""

            Write-Info "Executing migration..."
            $output = Invoke-Expression $psqlCommand 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "Migration applied successfully!"
                Write-Info ""
                Write-Info "Output:"
                Write-ColorOutput White $output
            } else {
                Write-Error-Message "Migration failed!"
                Write-ColorOutput Red $output
                exit 1
            }
        } finally {
            # Clear password from environment
            Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        }
    } else {
        Write-Error-Message "Could not parse Supabase URL"
        exit 1
    }
} else {
    Write-Warning-Message "PostgreSQL client (psql) not found!"
    Write-Info ""
    Write-Info "To apply migrations, you have the following options:"
    Write-Info ""
    Write-Info "1. Install PostgreSQL client:"
    Write-Info "   - Windows: Download from https://www.postgresql.org/download/windows/"
    Write-Info "   - Or use Supabase CLI: npm install -g supabase"
    Write-Info ""
    Write-Info "2. Apply migration manually:"
    Write-Info "   - Go to Supabase Dashboard > SQL Editor"
    Write-Info "   - Copy the contents of: $migrationPath"
    Write-Info "   - Paste and run in SQL Editor"
    Write-Info ""
    Write-Info "3. Use Supabase CLI:"
    Write-Info "   supabase db push --db-url <your-db-url>"
    Write-Info ""
    Write-Warning-Message "Opening migration file location..."

    # Open file explorer to migration file
    Start-Process explorer.exe -ArgumentList "/select,`"$migrationPath`""

    exit 1
}

Write-Info ""
Write-Header "Migration Complete!"

Write-Success "All database changes have been applied"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Verify tables in Supabase Dashboard"
Write-Info "2. Check RLS policies are enabled"
Write-Info "3. Test application features"
Write-Info "4. Run: flutter test"
Write-Info ""

# Verification queries
Write-Info "Running verification queries..."

$verificationSql = @"
-- Check if tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('favourites', 'user_devices', 'feedback')
ORDER BY table_name;

-- Check if orders columns exist
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'orders'
  AND column_name IN ('cancellation_reason', 'cancelled_at');

-- Count RLS policies
SELECT schemaname, tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN ('favourites', 'user_devices', 'feedback')
GROUP BY schemaname, tablename
ORDER BY tablename;
"@

Write-Info "Run these verification queries in Supabase SQL Editor:"
Write-ColorOutput White $verificationSql

Write-Info ""
Write-Success "Migration script completed!"
