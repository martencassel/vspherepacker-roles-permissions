param(
    [string]$FileName,
    [switch]$WhatIf = $true
)

Import-Module VMWare.VimAutomation.Core

function Show-Help {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\ApplyRoles.ps1 -FileName <path to yaml file> [-WhatIf]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -FileName" -ForegroundColor Green
    Write-Host "    Path to the YAML file containing role definitions." -ForegroundColor White
    Write-Host ""
    Write-Host "  -WhatIf" -ForegroundColor Green
    Write-Host "    Simulates the execution of the script without making any changes." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\ApplyRoles.ps1 -FileName permissions.yaml" -ForegroundColor Green
    Write-Host "  .\ApplyRoles.ps1 -FileName permissions.yaml -WhatIf" -ForegroundColor Green
}

 
 
Set-PSDebug -Trace 0
Set-StrictMode -Version Latest -ErrorAction Stop


Function VerifyPrereqs {
    $ErrorList = @()
    if($FileName -eq $null) {
        $ErrorList += "FileName is required"
    }

    if (-not (Test-Path $FileName)) {
        $ErrorList += "File: $FileName not found"
        exit
    }
    if (-not (Test-Path $FileName)) {
        Write-Error "File: $FileName not found"
        exit
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


# Read the permissions from the file (yaml file)
function ImportVIPermissions {
    param($FileName)
    $perms = cat $FileName|yq -o json|ConvertFrom-Json
    return $perms.permissions
}

function GetVAPIEntity {
    param([string]$EntityType, [string]$EntityName)
    $entity = $null
    switch ($EntityType) {
        "VMHost" {
            $entity = Get-VMHost -Name $EntityName
        }
        "Datacenter" {
            $entity = Get-Datacenter -Name $EntityName
        }
        "Folder" {
            $entity = Get-Folder -Name $EntityName
        }
        "VM" {
            $entity = Get-Folder -Name $EntityName
        }
        "Cluster" {
            $entity = Get-Cluster -Name $EntityName
        }
        "Datastore" {
            $entity = Get-Datastore -Name $EntityName
        }
        "Network" {
            $entity = Get-VirtualNetwork -Name $EntityName
        }
    }
    if ($null -eq $entity) {
        Write-Warning "Entity: $($EntityName) of type: $($EntityType) not found"
    }
    return $entity
}

function ResolveVAPIEntities($Perms) {
    $ResolvedRecords = @()
    Write-Host "$($WhatIf ? 'What if: ' : '')Resolving permissions with vapi objects" -ForegroundColor DarkGreen
    Write-Host "Resolving permissions with vapi objects" -ForegroundColor DarkGreen
    foreach ($record in $Perms) {
        $Entity = GetVAPIEntity -EntityType $record.entity_type -EntityName $record.entity_name
        if ($null -ne $Entity) {
            Write-Host "$($WhatIf ? 'What if: ' : '')Entity: $($record.entity_name) of type: $($record.entity_type) found"

            $Role = Get-VIRole -Name $record.role_name
            if ($null -eq $Role) {
                Write-Warning "Role: $($record.role_name) not found, skipping"
                continue
            }
            $Record = @{
                EntityType = $record.entity_type
                EntityName = $record.entity_name
                PrincipalName = $record.principal_name
                RoleName = $record.role_name
                Entity = $Entity
                Role = $Role
            }
            $ResolvedRecords += $Record
        } else {
            Write-Warning "Entity: $($record.entity_name) of type: $($record.entity_type) not found, skipping."
        }
    }
    Write-Host "$($WhatIf ? 'What if: ' : '')Resolved permissions with vapi objects" -ForegroundColor DarkGreen
    return $ResolvedRecords    
}

function ApplyVIPermissions($resolvedList) {
    foreach ($record in $resolvedList) {
        $Entity = $record.Entity
        $Role = $record.Role

        $PrincipalName = $record.PrincipalName
        $EntityName = $record.EntityName
        $EntityType = $record.EntityType

        $command = "New-VIPermission -Entity $Entity -Principal $PrincipalName -Role $Role -Confirm:$false"
        Write-Host "$($WhatIf ? 'What if: ' : '')Executing: $command" -ForegroundColor Cyan
              
        Write-Host "$($WhatIf ? 'What if: ' : '')Applying role: $($Role.Name) to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)" -ForegroundColor DarkGreen
        try {
            $Result = New-VIPermission -Entity $Entity -Principal $PrincipalName -Role $Role -Confirm:$false -WhatIf:$WhatIf
            Write-Host "$($WhatIf ? 'What if: ' : '')Role: $($Role.Name) applied successfully to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)" -ForegroundColor DarkGreen
        }
        catch {
            Write-Warning "Failed to apply role: $($Role.Name) to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)"
        }    
    }
}

function Main {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param()

    Write-Host "$($WhatIf ? 'What if: ' : '') Importing permissions from file: $($FileName)" -ForegroundColor DarkGreen
    $Perms = ImportVIPermissions -FileName $FileName
    Write-Host "Permissions imported successfully, here they are:" -ForegroundColor DarkGreen

    $ResolvedEntities = ResolveVAPIEntities -Perms $Perms
    Write-Host "$($WhatIf ? 'What if: ' : '') Permissions imported successfully, here they are:" -ForegroundColor DarkGreen


    Write-Host "$($WhatIf ? 'What if: ' : '') Applying permissions to entities:" -ForegroundColor DarkGreen

    ApplyVIPermissions -resolvedList $ResolvedEntities    

    Write-Host "$($WhatIf ? 'What if: ' : '') Permissions applied successfully:" -ForegroundColor DarkGreen
 
}


# Check if FileName is provided
if (-not $FileName) {
    Show-Help
    exit
}

$Errors = VerifyPrereqs
if ($null -ne $Errors) {
    Write-Error ("{0}" -f $Errors)
    exit
}

# Prompt for confirmation if WhatIf is not specified
if (-not $WhatIf) {
    $confirm = Read-Host "Would you like to add roles? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Host "Operation cancelled by user."
        exit
    }
}

Main -WhatIf:$WhatIf