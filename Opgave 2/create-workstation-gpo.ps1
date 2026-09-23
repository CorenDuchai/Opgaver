Import-Module GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GpoName  = "SpecLab - Workstation Security Baseline"
$TargetOU = "OU=Workstations,OU=Computers,OU=SpecLab,DC=spec,DC=test"

Write-Host ""
Write-Host "=== Creating workstation security GPO ==="

# ============================================================
# Create GPO if it does not already exist
# ============================================================

$Gpo = Get-GPO `
    -Name $GpoName `
    -ErrorAction SilentlyContinue

if ($Gpo) {
    Write-Host "[OK] GPO exists: $GpoName"
}
else {
    $Gpo = New-GPO `
        -Name $GpoName `
        -Comment "Security baseline for SpecLab workstations."

    Write-Host "[CREATED] GPO: $GpoName"
}


# ============================================================
# Link GPO to Workstations OU
# ============================================================

$Inheritance = Get-GPInheritance `
    -Target $TargetOU

$ExistingLink = $Inheritance.GpoLinks |
    Where-Object {
        $_.DisplayName -eq $GpoName
    }

if ($ExistingLink) {
    Write-Host "[OK] GPO already linked to Workstations OU"
}
else {
    New-GPLink `
        -Name $GpoName `
        -Target $TargetOU `
        -LinkEnabled Yes |
        Out-Null

    Write-Host "[LINKED] GPO -> Workstations OU"
}


# ============================================================
# Windows Defender Firewall
# ============================================================

Write-Host ""
Write-Host "=== Configuring Windows Firewall ==="

$FirewallProfiles = @(
    "DomainProfile",
    "PrivateProfile",
    "PublicProfile"
)

foreach ($Profile in $FirewallProfiles) {

    $RegistryPath =
        "HKLM\Software\Policies\Microsoft\WindowsFirewall\$Profile"

    Set-GPRegistryValue `
        -Name $GpoName `
        -Key $RegistryPath `
        -ValueName "EnableFirewall" `
        -Type DWord `
        -Value 1 |
        Out-Null

    Write-Host "[SET] Firewall enabled: $Profile"
}


# ============================================================
# Machine inactivity timeout
# ============================================================

Write-Host ""
Write-Host "=== Configuring inactivity lock ==="

Set-GPRegistryValue `
    -Name $GpoName `
    -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "InactivityTimeoutSecs" `
    -Type DWord `
    -Value 900 |
    Out-Null

Write-Host "[SET] Machine inactivity timeout: 900 seconds"


# ============================================================
# PowerShell Script Block Logging
# ============================================================

Write-Host ""
Write-Host "=== Configuring PowerShell logging ==="

Set-GPRegistryValue `
    -Name $GpoName `
    -Key "HKLM\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName "EnableScriptBlockLogging" `
    -Type DWord `
    -Value 1 |
    Out-Null

Write-Host "[SET] PowerShell Script Block Logging enabled"


# ============================================================
# PowerShell Module Logging
# ============================================================

Set-GPRegistryValue `
    -Name $GpoName `
    -Key "HKLM\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging" `
    -ValueName "EnableModuleLogging" `
    -Type DWord `
    -Value 1 |
    Out-Null

Set-GPRegistryValue `
    -Name $GpoName `
    -Key "HKLM\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" `
    -ValueName "*" `
    -Type String `
    -Value "*" |
    Out-Null

Write-Host "[SET] PowerShell Module Logging enabled"


# ============================================================
# Documentation report
# ============================================================

Write-Host ""
Write-Host "=== Creating GPO report ==="

$ReportDirectory = "C:\GPO-Reports"

if (-not (Test-Path $ReportDirectory)) {
    New-Item `
        -Path $ReportDirectory `
        -ItemType Directory |
        Out-Null
}

$ReportPath =
    "$ReportDirectory\SpecLab-Workstation-Security-Baseline.html"

Get-GPOReport `
    -Name $GpoName `
    -ReportType Html `
    -Path $ReportPath

Write-Host "[CREATED] GPO report: $ReportPath"


# ============================================================
# Verification
# ============================================================

Write-Host ""
Write-Host "=== Verification ==="

Get-GPO `
    -Name $GpoName |
    Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime |
    Format-Table -AutoSize

Write-Host ""

Get-GPInheritance `
    -Target $TargetOU |
    Select-Object -ExpandProperty GpoLinks |
    Where-Object {
        $_.DisplayName -eq $GpoName
    } |
    Select-Object DisplayName, Enabled, Enforced |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=== GPO configuration completed successfully ==="