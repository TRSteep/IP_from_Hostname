#
# Resolve IP from Hostnames in TXT files
#
#ByPass Restriction
Set-ExecutionPolicy Bypass -Scope Process

# Path
$Path = "C:\Media\dev\ps\Resolve_IP_from_DNS"

# DNS List
$DNSList = Get-Content $Path\resolve_ip_from_list_hostname.txt -Encoding UTF8

# Result Data
$FinalResult = @()

foreach ($DNS in $DNSList) {
    $IP = Resolve-DNSName $DNS

    $FinalResult += $IP
}

# Export XLX
$FinalResult | Export-Excel -Path $Path\resolve_ip_from_list_hostname.xlsx 

# Print Result
return $FinalResult