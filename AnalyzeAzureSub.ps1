Write-Host ""
Write-Host "Analyze Azure Subscription v0.1"
Write-Host "-------------------------------"

$vms = Get-AzureVM
$vmg = $vms | Group-Object {$_.ServiceName}
Write-Host ""
Write-Host "List of Cloud Services, and VM count"
Write-Host "------------------------------------"
$vms | Group-Object {$_.ServiceName} -NoElement
Write-Host ""
Write-Host "Checking for single instance VMs"
Write-Host ""

foreach($vmser in $vmg)
{
    $vms1 = $vmser.Group | Group-Object {$_.AvailabilitySetName}
    foreach($v1 in $vms1)
    {
        if($v1.Count -lt 2)
        {
            Write-Warning "VM '$($v1.Group[0].Name)' under '$($v1.Group[0].ServiceName)' Service is a Single instance VM!"
        }
    }
}

Write-Host ""
Write-Host "Testing VM Endpoint availability"
Write-Host "--------------------------------"
Write-Host ""
#Loop through each VM, and print it's Endpoint configuration
foreach($vm in $vms)
{
    Write-Host "$($vm.VM.RoleName) has $($vm.VM.ConfigurationSets[0].InputEndpoints.Count) endpoints"
    foreach($ep in $vm.VM.ConfigurationSets[0].InputEndpoints)
    {
        Try {
                if($ep.Protocol -eq "tcp") {
                $ms = 0
                for($i=0;$i -le 5;$i++) 
                {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    $cmd = Measure-Command {$tcp.Connect($ep.Vip, $ep.Port)}
                    $ms = $ms + $cmd.MilliSeconds
                    $tcp.Close()
                }
            }
            else
            {
            $udp = New-Object System.Net.Sockets.UdpClient
                $cmd = Measure-Command {$udp.Connect($ep.Vip, $ep.Port)}
            }
            Write-Host "$($ep.Name) $($ep.Vip): $($ep.Port) status OK (average latency $($ms/5)ms on 5 connection attempts)"
        }
        Catch {
            Write-Warning "$($ep.Name) $($ep.Vip): $($ep.Port) status ERROR"
        }
    }
            Write-Host ""
}

Write-Host ""

$dgroup = Get-AzureDisk | Where-Object { $_.AttachedTo } | Group-Object {$_.Medialink.Host.Split('.')[0]} -NoElement | Sort-Object Count -Descending
foreach($dg in $dgroup)
{
    if($dg.Count -ge 2) { 
        Write-Warning "Storage account '$($dg.Name)' has 40+ disks!"
        }
}
Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "List of Storage accounts, and number of disks in each"
Write-Host "-----------------------------------------------------"
Write-Host ""
$dgroup