function Get-VIEntity($EntityName, $EntityTypeName) {
    $Entity = $null
    try {
        if($null -eq $EntityName) {
            $Entity = Get-VIObjectByVIView -VIView (Get-View -ViewType $EntityTypeName)
        } else {
            $Entity = Get-VIObjectByVIView -VIView (Get-View -ViewType $EntityTypeName)|Where-Object {$_.Name -eq $EntityName}
        }
        return $Entity
    } catch {
        Write-Verbose "Error: $($_.Exception.Message)"
    }
    return $null
}

function Update-VIPermission($Permission, [string]$Principal, $Role, [bool]$Propagate) {
    if ($null -eq $Permission) {
        Write-Warning "Permission is null"
        return
    }
    if($Permission.GetType().Name -ne "PermissionImpl") {
        Write-Warning "Permission is not of type PermissionImpl"
        return
    }
    Write-Host "Updating permission for $($Permission.Entity.Name) with principal: $Principal"
    try {
        $Permission = Get-VIPermission -Entity $Permission.Entity -Principal $Permission.Principal -ErrorAction SilentlyContinue
        if($null -eq $Role) {
            Write-Verbose "Role is empty, only updating propagate"
            Write-Verbose "Set-VIPermission -Permission $Permission -Propagate:$Propagate"
            Set-VIPermission -Permission $Permission -Propagate:$Propagate;
        } else {
            Write-Verbose "Set-VIPermission -Permission $Permission -Role $Role -Propagate:$Propagate"
            Set-VIPermission -Permission $Permission -Role $Role -Propagate:$Propagate;
        }
    } catch {
        Write-Verbose "Error: $($_.Exception.Message)"
    }
}

function GetPermission([string]$Principal, [string]$RoleName, [string]$Entity) {
    if($null -eq $Principal) {
        Write-Warning "Principal is required"
        return
    }
    Write-Verbose "Get-VIPermission -Principal $Principal"
    $Result = Get-VIPermission -Principal $Principal
    if(($RoleName -ne $null) -and ($RoleName -ne "")) {
        Write-Host "Filtering permissions for role: $RoleName"
        $Result = $Result|Where-Object {$_.Role -eq $RoleName}
    }
    if(($Entity -ne $null) -and ($Entity -ne "")) {
        Write-Host "Filtering permissions for entity: $Entity"
        $Result = $Result|Where-Object {$_.Entity.Name -eq $Entity}
    }
    return $Result
}

# Get permission by (principal, role name)
$PermFromRole = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -RoleName "CNS-VM"
Update-VIPermission -Permission $permFPermFromRoleromRole -Propagate:$true

# Get permission by (principal, entity name)
$PermFromEntity = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns" -Entity "192.168.3.50"
$PermFromEntity

# Get all permissions for a principal
$AllPerms = GetPermission -Principal "LAB.LOCAL\k8s-batch-cns"
$AllPerms

 