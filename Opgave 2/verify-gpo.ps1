Write-Host "=== GPO Security Baseline Verification ==="

$fw = Get-NetFirewallProfile

Write-Host "Firewall Domain : $(( $fw | Where-Object Name -eq 'Domain' ).Enabled)"
Write-Host "Firewall Private: $(( $fw | Where-Object Name -eq 'Private' ).Enabled)"
Write-Host "Firewall Public : $(( $fw | Where-Object Name -eq 'Public' ).Enabled)"

$timeout = (Get-ItemProperty `
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System").InactivityTimeoutSecs

Write-Host "Lock timeout    : $timeout seconds"

$scriptBlock = (Get-ItemProperty `
    "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging").EnableScriptBlockLogging

Write-Host "ScriptBlock log : $scriptBlock"

$moduleLog = (Get-ItemProperty `
    "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging").EnableModuleLogging

Write-Host "Module logging  : $moduleLog"
