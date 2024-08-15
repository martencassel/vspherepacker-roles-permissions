Import-Module VMWare.VimAutomation.Core
Import-Module PSScriptAnalyzer

function Show-Help {
    Write-Output "Usage: ApplyRoles.ps1 -FileName <path to yaml file>"
    Write-Output "Example: ApplyRoles.ps1 -FileName ./permissions.yaml"
}


# Function to load and validate YAML file
function Load-YamlFile {

}

<#
.SYNOPSIS
    This script applies roles to entities in vCenter based on the permissions defined in a yaml file

    1. Imports the permissions from a yaml file, specified as a parameter to the script

    2. Resolves the entities in vCenter based on the entity type and entity name using 
       Get-Folder, Get-Datacenter, Get-Cluster, Get-Datastore, Get-VirtualNetwork, Get-VMHost etc

    3. Resolves each role to a vCenter role object using Get-VIRole, from the role name specified in the yaml file

    Usage:

    ./ApplyRoles.ps1 -FileName ./permissions.yaml

    cat permissions.yaml
#>
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
    Write-Host "Resolving permissions with vapi objects" -ForegroundColor DarkGreen
    foreach ($record in $Perms) {
        $Entity = GetVAPIEntity -EntityType $record.entity_type -EntityName $record.entity_name
        if ($null -ne $Entity) {
            Write-Host "Entity: $($record.entity_name) of type: $($record.entity_type) found"

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
    Write-Host $("Resolved entities {0} from permission file with vapi objects" -f $ResolvedRecords.Count) -ForegroundColor DarkGreen
    return $ResolvedRecords    
}

function ApplyVIPermissions($resolvedList) {
    foreach ($record in $resolvedList) {
        $Entity = $record.Entity
        $Role = $record.Role

        $PrincipalName = $record.PrincipalName
        $EntityName = $record.EntityName
        $EntityType = $record.EntityType

        Write-Host "Applying role: $($Role.Name) to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)" -ForegroundColor DarkGreen
        try {
            $Result = New-VIPermission -Entity $Entity -Principal $PrincipalName -Role $Role -Confirm:$false
            Write-Host "Role: $($Role.Name) applied successfully to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)" -ForegroundColor DarkGreen
        }
        catch {
            Write-Warning "Failed to apply role: $($Role.Name) to entity: $($EntityName) of type: $($EntityType) for principal: $($PrincipalName)"
        }
    }
}

function Main() {
    Write-Host "Importing permissions from file: $($FileName)" -ForegroundColor DarkGreen
    $Perms = ImportVIPermissions -FileName $FileName
    Write-Host "Permissions imported successfully, here they are:" -ForegroundColor DarkGreen
    $ResolvedEntities = ResolveVAPIEntities -Perms $Perms
    Write-Host "Applying permissions to entities" -ForegroundColor DarkGreen
    ApplyVIPermissions -resolvedList $ResolvedEntities    
    Write-Host "Permissions applied successfully" -ForegroundColor DarkGreen
    Get-VIPermission|Sort-Object
}


$Errors = VerifyPrereqs
if ($null -ne $Errors) {
    Write-Error ("{0}" -f $Errors)
    exit
}
Main

