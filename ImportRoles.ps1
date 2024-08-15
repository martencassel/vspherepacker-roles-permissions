param($FileName = $(throw "FileName is required"))
Set-PSDebug -Trace 0
Set-StrictMode -Version Latest -ErrorAction Stop

Function VerifyPrereqs() {
    $ErrorList = @()
    if($FileName -eq $null) {
        $ErrorList += "FileName is required"
    }
    $RequiredCmdlets = @("Get-VMHost", "Get-VIRole", "Get-VIPrivilege", "New-VIRole")
    for ($i = 0; $i -lt $RequiredCmdlets.Length; $i++) {
        if (-not (Get-Command -Name $RequiredCmdlets[$i] -ErrorAction SilentlyContinue)) {
            $ErrorList += "Cmdlet: $($RequiredCmdlets[$i]) not found"
        }
    }
    $VCenterConnected = $true
    try {
        $vmHost = Get-VMHost -ErrorAction Stop
        if ($vmHost) {
            $VCenterConnected = $true
        } else {
            $VCenterConnected = $false
        }
    } catch {
        $VCenterConnected = $false
    }
    if($VCenterConnected -eq $false) {
        $ErrorList += "Not connected to vSphere server"
        return $ErrorList
    }
    return $ErrorList
}

Function Main() {
    if (-not (Test-Path $FileName)) {
        Write-Error "File: $FileName not found"
        exit
    }
    if($FileName -eq $null) {
        Write-Error "FileName is required"
        exit
    }
    $RoleDefinitions = cat $FileName|yq -ojson|ConvertFrom-Json|Select-Object roles -ExpandProperty roles

    foreach($RoleDef in $RoleDefinitions) {
        $RoleName = $RoleDef.name
        $Privileges = $RoleDef.privileges

        $Role = Get-VIRole -Name $RoleName -ErrorAction SilentlyContinue
        if ($null -ne $Role) {
            Write-Host "Role: $RoleName already exists, skipping"
            continue
        }
        $PrivilegesList=@()
        foreach($Privilege in $Privileges) {
            $PrivilegesList += Get-VIPrivilege -Id $Privilege
        }
        Write-Host "Creating role: $RoleName, with privileges: $Privileges"
        $NewRole = New-VIRole -Name $RoleName -Privilege $PrivilegesList   
        if ($null -eq $NewRole) {
            Write-Error "Failed to create role: $RoleName"
            continue
        }
        Write-Host "Role: $RoleName created"

    }
}

$Errors = VerifyPrereqs
if ($null -ne $Errors) {
    Write-Error ("{0}" -f $Errors)
    exit
}
Main
