
EntityId      : Datacenter-datacenter-3
Entity        : Datacenter
Role          : ReadOnly
Principal     : LAB.LOCAL\k8s-batch-cns
Propagate     : True
IsGroup       : False
Uid           : /VIServer=lab.local\administrator@vcsa.lab.local:443/Datacenter=Datacenter-datacenter-3/Permission=ReadOnly
                -LAB.LOCAL\k8s-batch-cns-user/
ExtensionData : VMware.Vim.Permission

# Doesnt work
New-VIPermission -Entity Datacenter-datacenter-3 -Principal LAB.LOCAL\k8s-batch-cns -Role CNS-SEARCH-AND-SPBM -Confirm:False
