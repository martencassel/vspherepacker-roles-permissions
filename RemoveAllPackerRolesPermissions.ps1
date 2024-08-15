$packer_perms = Get-VIPermission|Where { $_.Principal -eq "LAB.LOCAL\packer" }
$packer_perms|Remove-VIPermission
Get-VIRole *packer*|Remove-VIRole

