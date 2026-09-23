Import-Module ActiveDirectory

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Domain    = Get-ADDomain
$DomainDN  = $Domain.DistinguishedName
$DomainDNS = $Domain.DNSRoot


# ============================================================
# Helper functions
# ============================================================

function Ensure-OU {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $OU = Get-ADOrganizationalUnit `
        -LDAPFilter "(ou=$Name)" `
        -SearchBase $Path `
        -SearchScope OneLevel `
        -ErrorAction SilentlyContinue

    if ($OU) {
        Write-Host "[OK] OU exists: $Name"
        return
    }

    New-ADOrganizationalUnit `
        -Name $Name `
        -Path $Path `
        -ProtectedFromAccidentalDeletion $true |
        Out-Null

    Write-Host "[CREATED] OU: $Name"
}


function Ensure-Group {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $Group = Get-ADGroup `
        -Filter "SamAccountName -eq '$Name'" `
        -ErrorAction SilentlyContinue

    if ($Group) {

        $ParentDN = $Group.DistinguishedName.Substring(
            $Group.DistinguishedName.IndexOf(",") + 1
        )

        if ($ParentDN -ne $Path) {

            Move-ADObject `
                -Identity $Group.DistinguishedName `
                -TargetPath $Path

            Write-Host "[MOVED] Group: $Name -> $Path"
        }
        else {
            Write-Host "[OK] Group exists: $Name"
        }

        return
    }

    New-ADGroup `
        -Name $Name `
        -SamAccountName $Name `
        -GroupCategory Security `
        -GroupScope Global `
        -Path $Path `
        -Description $Description

    Write-Host "[CREATED] Group: $Name"
}


function Ensure-User {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Group,

        [Parameter(Mandatory)]
        [SecureString]$Password
    )

    $User = Get-ADUser `
        -Filter "SamAccountName -eq '$SamAccountName'" `
        -Properties Enabled `
        -ErrorAction SilentlyContinue

    if ($User) {

        $ParentDN = $User.DistinguishedName.Substring(
            $User.DistinguishedName.IndexOf(",") + 1
        )

        if ($ParentDN -ne $Path) {

            Move-ADObject `
                -Identity $User.DistinguishedName `
                -TargetPath $Path

            Write-Host "[MOVED] User: $SamAccountName -> $Path"
        }
        else {
            Write-Host "[OK] User exists: $SamAccountName"
        }

        # Repair account if an earlier creation failed because
        # of password policy and left the account disabled.
        if (-not $User.Enabled) {

            Write-Host "[FIX] User is disabled - setting password and enabling account: $SamAccountName"

            Set-ADAccountPassword `
                -Identity $SamAccountName `
                -Reset `
                -NewPassword $Password

            Enable-ADAccount `
                -Identity $SamAccountName

            Set-ADUser `
                -Identity $SamAccountName `
                -ChangePasswordAtLogon $true

            Write-Host "[ENABLED] User: $SamAccountName"
        }
    }
    else {

        New-ADUser `
            -Name $Name `
            -SamAccountName $SamAccountName `
            -UserPrincipalName "$SamAccountName@$DomainDNS" `
            -Path $Path `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "[CREATED] User: $SamAccountName"
    }


    # --------------------------------------------------------
    # Group membership
    # --------------------------------------------------------

    $Membership = Get-ADGroupMember `
        -Identity $Group `
        -ErrorAction Stop |
        Where-Object {
            $_.SamAccountName -eq $SamAccountName
        }

    if ($Membership) {

        Write-Host "[OK] $SamAccountName already member of $Group"
    }
    else {

        Add-ADGroupMember `
            -Identity $Group `
            -Members $SamAccountName

        Write-Host "[ADDED] $SamAccountName -> $Group"
    }
}


# ============================================================
# OU structure
# ============================================================

Write-Host ""
Write-Host "=== Creating OU structure ==="

Ensure-OU `
    -Name "SpecLab" `
    -Path $DomainDN

$RootOU = "OU=SpecLab,$DomainDN"

Ensure-OU `
    -Name "Users" `
    -Path $RootOU

Ensure-OU `
    -Name "Computers" `
    -Path $RootOU

Ensure-OU `
    -Name "Groups" `
    -Path $RootOU


$UsersOU     = "OU=Users,$RootOU"
$ComputersOU = "OU=Computers,$RootOU"
$GroupsOU    = "OU=Groups,$RootOU"


Ensure-OU `
    -Name "Admins" `
    -Path $UsersOU

Ensure-OU `
    -Name "Developers" `
    -Path $UsersOU

Ensure-OU `
    -Name "Guests" `
    -Path $UsersOU


Ensure-OU `
    -Name "Servers" `
    -Path $ComputersOU

Ensure-OU `
    -Name "Workstations" `
    -Path $ComputersOU


# ============================================================
# Security groups
# ============================================================

Write-Host ""
Write-Host "=== Creating security groups ==="

Ensure-Group `
    -Name "GG-Admins" `
    -Path $GroupsOU `
    -Description "Administrative role group"

Ensure-Group `
    -Name "GG-Developers" `
    -Path $GroupsOU `
    -Description "Developer role group"

Ensure-Group `
    -Name "GG-Guests" `
    -Path $GroupsOU `
    -Description "Guest role group"


# ============================================================
# Test users
# ============================================================

Write-Host ""
Write-Host "=== Creating test users ==="

Write-Host "Password must meet domain complexity requirements"
Write-Host "and must not contain the username."

$Password = Read-Host `
    "Enter temporary password for lab accounts" `
    -AsSecureString


Ensure-User `
    -Name "Admin User" `
    -SamAccountName "admin1" `
    -Path "OU=Admins,$UsersOU" `
    -Group "GG-Admins" `
    -Password $Password


Ensure-User `
    -Name "Developer User" `
    -SamAccountName "dev1" `
    -Path "OU=Developers,$UsersOU" `
    -Group "GG-Developers" `
    -Password $Password


Ensure-User `
    -Name "Guest User" `
    -SamAccountName "guest1" `
    -Path "OU=Guests,$UsersOU" `
    -Group "GG-Guests" `
    -Password $Password


# ============================================================
# Verification
# ============================================================

Write-Host ""
Write-Host "=== Verification ==="

Get-ADUser `
    -Filter * `
    -SearchBase $UsersOU `
    -Properties Enabled |
    Select-Object SamAccountName, Enabled |
    Format-Table -AutoSize


Write-Host ""
Write-Host "=== AD structure completed successfully ==="