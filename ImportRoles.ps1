param($FileName = $(throw "FileName is required"))
Set-PSDebug -Trace 0
Set-StrictMode -Version Latest -ErrorAction Stop

Function Main() {
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


Main

