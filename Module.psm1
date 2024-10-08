<#

---

permissions:

  - role: "CNS-SEARCH-AND-SPBM"
    entity: "Folder-group-d1"
    view_type: "Folder"
    principal: "LAB.LOCAL\\k8s-batch-cns"
    propagate: "no"

  - role: "ReadOnly"
    entity: "Datacenter"
    view_type: "Datacenter"
    principal: "LAB.LOCAL\\k8s-batch-cns"
    propagate: "no"

  - role: "CNS-HOST-CONFIG-STORAGE"
    entity: "192.168.3.50"
    view_type: "HostSystem"
    principal: "LAB.LOCAL\\k8s-batch-cns"
    propagate: "no"

  - role: "CNS-Datastore"
    entity: "datastore1"
    view_type: "Datastore"
    principal: "LAB.LOCAL\\k8s-batch-cns"
    propagate: "no"

  - role_name: "CNS-VM"
    entity: "k8s-batch"
    view_type: "Folder"
    principal: "LAB.LOCAL\\k8s-batch-cns"
    propagate: "no"


#>
function Import-Yaml {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )
    if (-not (Test-Path $FileName)) {
        Write-Error "File: $FileName not found"
        return $null
    }
    $FromYaml = ConvertFrom-Yaml -Path $FileName
    if ($null -eq $FromYaml) {
        Write-Error "Error importing permissions from file: $FileName"
        return $null
    }
    $permissions = $FromYaml.permissions
    foreach($perm in $permissions) {
        $perm
    }
}
Export-ModuleMember -Function Import-Yaml

<#
    .SYNOPSIS
    Ensure-VIPermission

    .DESCRIPTION
    Ensure-VIPermission

    .PARAMETER Entity
    The entity object
#>
Function Ensure-VIPermission {
    # If it doesn't exist, create it
    param (
        [Parameter(Mandatory=$true)]
        [object]$Entity,

        [Parameter(Mandatory=$true)]
        [string]$Principal,

        [Parameter(Mandatory=$true)]
        [string]$Role,

        [Parameter(Mandatory=$true)]
        [string]$Propagate,

        [switch]$WhatIf = $true
    )

    $prefix = if ($WhatIf) { "What if: " } else { "" }

    Write-Host "${prefix}Ensuring permission for entity: $($Entity.Name) with principal: $Principal"

    
    $Permission = Get-VIPermission -Entity $Entity -Principal $Principal -ErrorAction SilentlyContinue
    $Permission
    # if ($null -eq $Permission) {
    #     Write-Host "${prefix}Permission not found for entity: $($Entity.Name) and principal: $Principal"
    #     Write-Verbose "Trying to create it:"

    #     # Map "yes" to $true and "no" to $false for propagate
    #     $propagateValue = switch ($Propagate) {
    #         "yes" { $true }
    #         "no" { $false }
    #         default { $false }
    #     }
    #     $Entity
    #     New-VIPermission -Entity $Entity.Name -Principal $Principal -Role $Role -Propagate $propagateValue -WhatIf:$WhatIf
    #     return
    # }

    # Write-Host "${prefix}Permission found for entity: $($Entity.Name) and principal: $Principal"
}
Export-ModuleMember -Function Ensure-VIPermission

<#
    .SYNOPSIS
    Convert YAML to PSObject

    .DESCRIPTION
    Convert YAML to PSObject

    .PARAMETER Path
    The path to the YAML file

    .EXAMPLE

    ConvertFrom-Yaml -Path "permissions.yaml"
#>
function ConvertFrom-Yaml {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "File: $Path not found"
        return $null
    }

    try {
        if ($IsLinux) {
            # Use cat and yq on Linux
            $FromYamlPSObject = cat $Path | yq -o json | ConvertFrom-Json
        } else {
            # Use YamlDotNet on Windows
            if (-not (Get-Module -ListAvailable -Name YamlDotNet)) {
                Install-Package -Name YamlDotNet -Source 'nuget.org' -Force -Scope CurrentUser
            }
            Import-Module YamlDotNet

            $yamlContent = Get-Content -Path $Path -Raw
            $yaml = [YamlDotNet.Serialization.Deserializer]::new()
            $parsedYaml = $yaml.Deserialize([System.IO.StringReader]::new($yamlContent))
            $FromYamlPSObject = $parsedYaml | ConvertTo-Json | ConvertFrom-Json
        }
        return $FromYamlPSObject
    } catch {
        Write-Error "Error importing data from YAML file: $($_.Exception.Message)"
        return $null
    }
}

Export-ModuleMember -Function ConvertFrom-Yaml

<#
    .SYNOPSIS
    Get VI Entity

    .DESCRIPTION
    Get VI Entity

    .PARAMETER EntityName
    The entity name

    .PARAMETER EntityTypeName
    The entity type name

    .EXAMPLE

    Get-VIEntity -EntityName "MyVirtualMachine" -EntityTypeName "VirtualMachine"

#>
function Get-VIEntity {
    param (
        [Parameter(Mandatory=$true)]
        [string]$EntityName,

        [Parameter(Mandatory=$true)]
        [string]$EntityTypeName
    )

    try {
        if ($null -eq $EntityName) {
            # Get all
            $Entity = Get-VIObjectByVIView -VIView (Get-View -ViewType $EntityTypeName)
        } else {
            # Get by name
            $Entity = Get-VIObjectByVIView -VIView (Get-View -ViewType $EntityTypeName) | Where-Object { $_.Name -eq $EntityName }
        }
        return $Entity
    } catch {
        Write-Verbose "Error: $($_.Exception.Message)"
        return $null
    }
}
Export-ModuleMember -Function Get-VIEntity

<#
    .SYNOPSIS
    Update VI Permission

    .DESCRIPTION
    Update VI Permission

    .PARAMETER Permission
    The permission object

    .PARAMETER Principal
    The principal name

    .PARAMETER Role
    The role object

    .PARAMETER Propagate
    Propagate the permission

#>
function Update-VIPermission {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Permission,

        [Parameter(Mandatory=$false)]
        [string]$Principal,

        [Parameter(Mandatory=$false)]
        [object]$Role,

        [Parameter(Mandatory=$false)]
        [bool]$Propagate,

        [switch]$WhatIf = $true
    )

    # Print WhatIf status
    if ($WhatIf) {
        Write-Host "WhatIf is enabled"
    } else {
        Write-Host "WhatIf is disabled"
    }

    if ($Permission.GetType().Name -ne "PermissionImpl") {
        Write-Warning "Permission is not of type PermissionImpl"
        Write-Verbose "Permission type: $($Permission.GetType().Name)"
        return
    }

    $prefix = if ($WhatIf) { "What if: " } else { "" }
    Write-Host "${prefix}Updating permission for $($Permission.Entity.Name) with principal: $Principal"

    try {
        $Permission = Get-VIPermission -Entity $Permission.Entity -Principal $Permission.Principal -ErrorAction SilentlyContinue

        if ($null -eq $Role) {
            Write-Verbose "${prefix}Role is empty, only updating propagate"
            Write-Verbose "${prefix}Set-VIPermission -Permission $Permission -Propagate:$Propagate"
            if (-not $WhatIf) {
                Set-VIPermission -Permission $Permission -Propagate:$Propagate -WhatIf:$WhatIf
            }
        } else {
            Write-Verbose "${prefix}Set-VIPermission -Permission $Permission -Role $Role -Propagate:$Propagate"
            if (-not $WhatIf) {
                Set-VIPermission -Permission $Permission -Role $Role -Propagate:$Propagate -WhatIf:$WhatIf
            }
        }
    } catch {
        Write-Error "${prefix}Error updating permission: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function Update-VIPermission


<#
.SYNOPSIS
    Get permission for a principal

.DESCRIPTION

    Get permission for a principal

.PARAMETER Principal
    Principal name

.PARAMETER RoleName
    Role name

.PARAMETER Entity
    Entity name

.EXAMPLE
    $perm = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -RoleName "CNS-VM"

    $perm = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns"

    $perm = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -Entity "vm"

#>
function GetPermission {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Principal,

        [Parameter(Mandatory=$false)]
        [string]$RoleName,

        [Parameter(Mandatory=$false)]
        [string]$Entity
    )

    if (-not $Principal) {
        Write-Warning "Principal is required"
        return
    }

    Write-Verbose "Retrieving permissions for principal: $Principal"
    $Result = Get-VIPermission -Principal $Principal

    if ($RoleName) {
        Write-Verbose "Filtering permissions for role: $RoleName"
        $Result = $Result | Where-Object { $_.Role -eq $RoleName }
    }

    if ($Entity) {
        Write-Verbose "Filtering permissions for entity: $Entity"
        $Result = $Result | Where-Object { $_.Entity.Name -eq $Entity }
    }

    return $Result
}
Export-ModuleMember -Function GetPermission

function Example1() {

    # Get permission by (principal, role name)

    # WhatIf is enabled by default
    $PermFromRole = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -RoleName "CNS-VM"
    Update-VIPermission -Permission $PermFromRole -Propagate:$true -WhatIf:$true

    # WhatIf is disabled
    $PermFromRole = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -RoleName "CNS-VM"
    Update-VIPermission -Permission $PermFromRole -Propagate:$true -WhatIf:$false

    # Get permission by (principal, entity name)
    $PermFromEntity = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -Entity "192.168.3.50"
    $PermFromEntity

    # Get all permissions for a principal
    $AllPerms = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns"
    $AllPerms 
}
Export-ModuleMember -Function Example1


Function Example2() {
    # Import the module containing the Get-VIEntity function
    Import-Module -Name ./Module.psm1

    # Example 1: Retrieve a specific Virtual Machine by name
    $vmName = "MyVirtualMachine"
    $vmEntity = Get-VIEntity -EntityName $vmName -EntityTypeName "VirtualMachine"

    if ($vmEntity) {
        Write-Host "Virtual Machine '$vmName' found:"
        $vmEntity | Format-Table -Property Name, PowerState, Guest
    } else {
        Write-Host "Virtual Machine '$vmName' not found."
    }

    # Example 2: Retrieve all Datastores
    $datastoreEntities = Get-VIEntity -EntityName $null -EntityTypeName "Datastore"

    if ($datastoreEntities) {
        Write-Host "Datastores found:"
        $datastoreEntities | Format-Table -Property Name, FreeSpaceMB, CapacityMB
    } else {
        Write-Host "No Datastores found."
    }

    # Example 3: Retrieve a specific Host by name
    $hostName = "MyHost"
    $hostEntity = Get-VIEntity -EntityName $hostName -EntityTypeName "HostSystem"

    if ($hostEntity) {
        Write-Host "Host '$hostName' found:"
        $hostEntity | Format-Table -Property Name, ConnectionState, PowerState
    } else {
        Write-Host "Host '$hostName' not found."
    }
}
Export-ModuleMember -Function Example2

Function Example3() {
    # Import the module containing the GetPermission function
    Import-Module -Name ./Module.psm1


    # Example 1: Retrieve all permissions for a specific principal
    $principal = "LAB.LOCAL\Administrator"
    $permissions = GetPermission -Principal $principal
    Write-Verbose "All Permissions for principal '$principal':"
    $permissions|fl

    if ($permissions) {
        Write-Host "Permissions for principal '$principal':"
        $permissions | Format-Table -Property Entity, Role, Propagate
    } else {
        Write-Host "No permissions found for principal '$principal'."
    }

    # Example 2: Retrieve permissions for a specific principal and role
    $roleName = "Admin"
    Write-Verbose "Retrieving permissions for principal: $principal with role: $roleName"
    $permissionsForRole = GetPermission -Principal $principal -RoleName $roleName

    if ($permissionsForRole) {
        Write-Host "Permissions for principal '$principal' with role '$roleName':"
        $permissionsForRole | Format-Table -Property Entity, Role, Propagate
    } else {
        Write-Host "No permissions found for principal '$principal' with role '$roleName'."
    }

    # Example 3: Retrieve permissions for a specific principal and entity
    Write-Verbose "Retrieving permissions for principal: $principal on entity: $entityName"
    $entityName = "Datacenters"
    Write-Verbose "Retrieving permissions for principal: $principal on entity: $entityName"
    $permissionsForEntity = GetPermission -Principal $principal -Entity $entityName

    if ($permissionsForEntity) {
        Write-Host "Permissions for principal '$principal' on entity '$entityName':"
        $permissionsForEntity | Format-Table -Property Entity, Role, Propagate
    } else {
        Write-Host "No permissions found for principal '$principal' on entity '$entityName'."
    }

    # Example 4: Retrieve permissions for a specific principal, role, and entity
    Write-Verbose "Retrieving permissions for principal: $principal with role: $roleName on entity: $entityName"
    $permissionsForRoleAndEntity = GetPermission -Principal $principal -RoleName $roleName -Entity $entityName

    if ($permissionsForRoleAndEntity) {
        Write-Host "Permissions for principal '$principal' with role '$roleName' on entity '$entityName':"
        $permissionsForRoleAndEntity | Format-Table -Property Entity, Role, Propagate
    } else {
        Write-Host "No permissions found for principal '$principal' with role '$roleName' on entity '$entityName'."
    }
}
Export-ModuleMember -Function Example3


<#
    .SYNOPSIS
    Get VI Object by VI View

    .DESCRIPTION

    Get VI Object by VI View

    .PARAMETER VIView
    The VI View

    .EXAMPLE

    $FolderViews = Get-View -ViewType Folder
    $Folders = Get-VIObjectByVIView $FolderViews
    $Folders | Format-Table -Property Name, Parent
#>
Function Get-VIObject($Name, $ViewType) {
    $FolderViews = Get-View -ViewType Folder
    $Folders = Get-VIObjectByVIView $FolderViews
    return $Folders | Where-Object { $_.Name -eq $Name }
}

<#
    .SYNOPSIS
    Set VI Permission.

    .DESCRIPTION

    Set VI Permission, if it doesn't exist, create it.
    This is intended to be Idempotent.

    .PARAMETER Name
    The name of the entity

    .PARAMETER ViewType
    The view type of the entity. Get-VIObjectByVIView will be used to find the entity.
    Each viewtype can be fetched by Get-VIVIew -ViewType <ViewType>.

    .PARAMETER Role
    The role name

    .PARAMETER Principal
    The principal name

    .PARAMETER Propagate
    Propagate the permission

    .EXAMPLE
    
        SetVIPermission `
            -Role "CNS-SEARCH-AND-SPBM" `
            -Name "Datacenter" `
            -ViewType "Datacenter" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

        SetVIPermission `
            -Role "ReadOnly" `
            -Name "Datacenter" `
            -ViewType "Datacenter" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

        SetVIPermission `
            -Role "CNS-HOST-CONFIG-STORAGE" `
            -Name "192.168.3.50" `
            -ViewType "HostSystem" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

        SetVIPermission `
            -Role "CNS-Datastore" `
            -Name "datastore1" `
            -ViewType "Datastore" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

        SetVIPermission `
            -Role "CNS-VM" `
            -Name "k8s-batch" `
            -ViewType "Folder" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

        SetVIPermission `
            -Role "CNS-VM" `
            -Name "k8s-batch" `
            -ViewType "Folder" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $true

        Get-VIPermission -Principal "LAB.LOCAL\k8s-batch-cns" | Format-Table -Property Entity, Role, Propagate

        SetVIPermission `
            -Role "CNS-VM" `
            -Name "k8s-batch" `
            -ViewType "Folder" `
            -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false

#>
function SetVIPermission {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$ViewType,

        [Parameter(Mandatory=$true)]
        [string]$Role,

        [Parameter(Mandatory=$true)]
        [string]$Principal,

        [Parameter(Mandatory=$false)]
        [bool]$Propagate,

        # WhatIf
        [switch]$WhatIf = $true
    )
    # Lookup the entity by its viewtype
    $View = $null
    try {
        $View = Get-View -ViewType $ViewType
    } catch {
        Write-Warning "ViewType: $ViewType not found"
        return
    }
    # Find the entity by name from its viewtype
    $EntityObject = Get-VIObjectByVIView $View| Where-Object { $_.Name -eq $Name }
    if($null -eq $EntityObject) {
        Write-Warning "Entity: $Name of type: $ViewType not found"
        return
    }
    # Lookup role
    $RoleObject = Get-VIRole -Name $Role
    if ($null -eq $RoleObject) {
        Write-Warning "Role: $Role not found"
        return
    }
    $RoleObject

    # Find PRINCIPAL
    $PrincipalObject = Get-VIAccount -Name $Principal
    if ($null -eq $PrincipalObject) {
        Write-Warning "Principal: $Principal not found"
        return
    }

    # Check if propagate is set
    $propagateValue = if ($Propagate) { $true } else { $false }


    # Does it exist already ? 
    $Permission = Get-VIPermission -Entity $EntityObject -Principal $Principal
    if($null -eq $Permission) {
        Write-Host "Permission not found for entity: $($EntityObject.Name) and principal: $Principal"
        Write-Verbose "Trying to create it:"
        New-VIPermission -Entity $EntityObject -Principal $Principal -Role $RoleObject -Propagate $propagateValue -WhatIf:$WhatIf
        return
    } else {
        Write-Host "Permission found for entity: $($EntityObject.Name) and principal: $Principal"
        Write-Host "Updating it:"
        Set-VIPermission -Permission $Permission -Role $RoleObject -Propagate $propagateValue -WhatIf:$WhatIf   
    }
}
Export-ModuleMember -Function SetVIPermission

<#
    .SYNOPSIS
    Import permissions from a YAML file

    .DESCRIPTION
    Import permissions from a YAML file

    .PARAMETER FileName
    The name of the YAML file to import

    .PARAMETER WhatIf
    Perform a dry run of the import

    .EXAMPLE

    Import-Permissions -FileName "permissions.yaml"
#>
function Import-Permissions {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )

    if (-not (Test-Path $FileName)) {
        Write-Error "File: $FileName not found"
        return
    }

    if (-not ($FileName -like "*.yaml")) {
        Write-Error "File: $FileName must be a YAML file"
        return
    }

    $PSObject = ConvertFrom-Yaml -Path $FileName
    $Permissions = $PSObject.permissions

    if ($null -eq $Permissions) {
        Write-Error "Permissions is empty"
        return
    }

    $requiredProperties = @('role', 'name', 'view_type', 'principal', 'propagate')
    foreach ($property in $requiredProperties) {
        if (-not ($Permissions | Get-Member -Name $property -ErrorAction SilentlyContinue)) {
            Write-Error "$property is required, but it's missing"
            return
        }
    }

    foreach ($perm in $Permissions) {
        if ($null -eq $perm) {
            Write-Error "Permission is empty"
            return
        }

        if ([string]::IsNullOrEmpty($perm.role)) {
            Write-Error "Role is required, but it's empty"
            return
        }

        $propagateValue = switch ($perm.propagate) {
            "yes" { $true }
            "no" { $false }
            default { $false }
        }

        if ($PSCmdlet.ShouldProcess("Set VIPermission for $($perm.name)")) {
            Write-Host "SetVIPermission -Name $($perm.name) -ViewType $($perm.view_type) -Role $($perm.role) -Principal $($perm.principal) -Propagate $propagateValue -WhatIf:$WhatIf"
            SetVIPermission -Name $perm.name -ViewType $perm.view_type -Role $perm.role -Principal $perm.principal -Propagate $propagateValue -WhatIf:$WhatIf
        }
    }

    # List all permissions
    Write-Host "Get-VIPermission -Principal $($perm.principal)"
    Get-VIPermission -Principal $perm.principal | Format-Table -Property Entity, Role, Propagate
}
Export-ModuleMember -Function Import-Permissions

<#
    .SYNOPSIS
    Import roles from a YAML file

    .DESCRIPTION
    Import roles from a YAML file

    .PARAMETER FileName
    The name of the YAML file to import

    .PARAMETER WhatIf
    Perform a dry run of the import

    .EXAMPLE

    Import-Roles -FileName "roles.yaml"
#>
function Import-Roles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [switch]$WhatIf = $true

    )

    if (-not (Test-Path $FileName)) {
        Write-Error "File: $FileName not found"
        return
    }

    if (-not ($FileName -like "*.yaml")) {
        Write-Error "File: $FileName must be a YAML file"
        return
    }

    $PSObject = ConvertFrom-Yaml -Path $FileName
    $Roles = $PSObject.roles

    if ($null -eq $Roles) {
        Write-Error "Roles is empty"
        return
    }

    $requiredProperties = @('name', 'privileges')

    foreach ($role in $Roles) {
        if ($null -eq $role) {
            Write-Error "Role is empty"
            return
        }

        foreach ($property in $requiredProperties) {
            if (-not ($role | Get-Member -Name $property -ErrorAction SilentlyContinue)) {
                Write-Error "$property is required, but it's missing"
                return
            }
        }

        if ([string]::IsNullOrEmpty($role.name)) {
            Write-Error "Role name is required, but it's empty"
            return
        }

        if ($null -eq $role.privileges) {
            Write-Error "Privileges is empty"
            return
        }

        $VIPrivileges=@()
        for ($i=0; $i -lt $role.privileges.Length; $i++) {
            $privilege = $role.privileges[$i]
            $VIPrivileges += Get-VIPrivilege -Id $privilege
        }

        # Log role name with color
        Write-Host -ForegroundColor Green "Processing Role: $($role.name)"

        # Log privileges with color
        Write-Host -ForegroundColor Cyan "Privileges:"
        foreach ($privilege in $role.privileges) {
            Write-Host -ForegroundColor Yellow "  - $privilege"
        }

        # If the role doesn't exist, create it
        $ExistingRole = Get-VIRole -Name $role.name
        if ($null -eq $ExistingRole) {
            Write-Host "Role: $($role.name) not found"
            Write-Host "Creating role: $($role.name)"
            Write-Host "Create-VIRole -Name $($role.name) -Privileges $($role.privileges) -WhatIf:$WhatIf"
            New-VIRole -Name $role.name -Privilege $VIPrivileges -WhatIf:$WhatIf
            continue
        } else {
            Write-Host "Role: $($role.name) found"
        }
    }
}
Export-ModuleMember -Function Import-Roles
