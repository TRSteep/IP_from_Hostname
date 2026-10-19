#
# Resolve IP from Hostnames in TXT files
# V0.2
<#
.SYNOPSIS
    Resolve IP addresses from hostnames listed in a text file

.DESCRIPTION
    This script reads hostnames from a TXT file and resolves their IP addresses using DNS queries.
    
.PARAMETER Path
    The path to the directory containing the input file
    
.EXAMPLE
    .\resolve_ip_from_list_hostname.ps1 -Path "C:\Scripts"
#>

param(
    [string]$Path = $PSScriptRoot,
    [switch]$Verbose
)

# Validate input path
if (-not (Test-Path $Path)) {
    throw "Directory not found: $Path"
}

# Path to DNS list file
$DNSListFilePath = Join-Path $Path "resolve_ip_from_list_hostname.txt"

# Validate DNS list file exists
if (-not (Test-Path $DNSListFilePath)) {
    throw "DNS list file not found: $DNSListFilePath"
}

# Read and process DNS list, filtering out empty lines and comments
$DNSList = Get-Content $DNSListFilePath -Encoding UTF8 | 
    Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^#' } |
    Sort-Object -Unique

if ($Verbose) {
    Write-Host "Processing $($DNSList.Count) unique hostnames..." -ForegroundColor Green
}

# Result Data
$FinalResult = @()

try {
    # Process each hostname with error handling
    $ProgressCounter = 0
    foreach ($DNS in $DNSList) {
        $ProgressCounter++
        
        if ($Verbose) {
            Write-Host "Processing [$ProgressCounter/$($DNSList.Count)] $DNS" -ForegroundColor Yellow
        }
        
        try {
            # Resolve DNS with error handling
            $IPs = Resolve-DNSName $DNS -ErrorAction Stop
            
            foreach ($ip in $IPs) {
                $FinalResult += [PSCustomObject]@{
                    Hostname = $DNS
                    IP = $ip.IPAddress
                    RecordType = $ip.Type
                    Timestamp = Get-Date
                }
            }
        } catch {
            # Handle DNS resolution errors gracefully
            Write-Warning "Failed to resolve DNS: $DNS. Error: $($_.Exception.Message)"
            
            $FinalResult += [PSCustomObject]@{
                Hostname = $DNS
                IP = "ERROR"
                RecordType = "N/A"
                Timestamp = Get-Date
                Error = $_.Exception.Message
            }
        }
    }
    
    # Export to Excel with proper filename
    $Date = Get-Date -Format "yyyyMMdd"
    $OutputPath = Join-Path $Path "$Date`_resolve_ip_from_list_hostname.xlsx"
    
    if ($Verbose) {
        Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
    }
    
    # Export to Excel (assuming ImportExcel module is available)
    try {
        $FinalResult | Export-Excel -Path $OutputPath -ErrorAction Stop
        Write-Host "Results successfully exported to: $OutputPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to export to Excel. Saving as CSV instead."
        
        # Fallback to CSV if Excel export fails
        $CSVPath = Join-Path $Path "$Date`_resolve_ip_from_list_hostname.csv"
        $FinalResult | Export-Csv -Path $CSVPath -NoTypeInformation
        Write-Host "Results exported to CSV: $CSVPath" -ForegroundColor Green
    }
    
} catch {
    Write-Error "An error occurred during processing: $($_.Exception.Message)"
    throw
}

# Print final result count
Write-Host "Processed $($FinalResult.Count) records total." -ForegroundColor Cyan

# Return results for further use if needed
return $FinalResult