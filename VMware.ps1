$vmrun = 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe'

function Get-Powerstate {
    if ($null -ne (& $vmrun list | Select-String -NoEmphasis ('\\' + $args[0] + '.vmx'))) {
        return $True
    } else {
        return $False
    }
}

function Get-VMpath {
    return (Get-ChildItem -Path E:\VMs\*\$args.vmx | Select-Object -ExpandProperty FullName)
}
function Use-VMrun {
    [CmdletBinding()] Param([ValidateSet('Start', 'Status', 'Stop', 'Restart', 'SSH')] $Action)
    DynamicParam {
 
            # Set the dynamic parameters' name
            $ParameterName = 'Name'
 
            # Create the dictionary
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
 
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
 
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 1
 
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)
 
            # Generate and set the ValidateSet
            $arrSet = (Get-ChildItem -Path E:\VMs\*\*.vmx | Select-Object -ExpandProperty Name).Replace('.vmx','')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet + 'All')
 
            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)
 
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
    }
    begin {
        # Bind the parameter to a friendly variable
        $Name = $PsBoundParameters[$ParameterName]

        if ($Name -eq 'All') {
            $allVMS = (Get-ChildItem -Path E:\VMs\*\*.vmx | Select-Object -ExpandProperty Name).Replace('.vmx','')
            switch ($Action) {
                'Start' {
                    Write-Host "Start all machines? (`e[32my`e[0m/`e[31mN`e[0m): " -NoNewLine
                    $opcao = Read-Host
                    if ($opcao -eq 'y') {
                        foreach ($vm in $allVMS) {
                            if (Get-Powerstate $vm) {
                                Write-Host "[`e[32m+`e[0m] $vm is already ON."
                            } else {
                                Write-Host "[`e[33m*`e[0m] Starting $vm..."
                                & $vmrun -T ws start (Get-VMpath $vm) nogui
                                Write-Host "[`e[32m+`e[0m] $vm ON."
                            }
                        }
                    }
                }
                'Status' {
                    Write-Host 'Getting status for all machines: '
                    foreach ($vm in $allVMS) {
                        if (Get-Powerstate $vm) {
                            Write-Host "[`e[32m+`e[0m] $vm is ON at:`e[32m" (& $vmrun -T ws getGuestIPAddress (Get-VMpath $vm) -wait)"`e[0m"
                        } else {
                            Write-Host "[`e[31m-`e[0m] $vm is OFF."
                        }
                    }
                }
                'Stop' {
                    Write-Host "Stop all machines? (`e[32my`e[0m/`e[31mN`e[0m): " -NoNewLine
                    $opcao = Read-Host
                    if ($opcao -eq 'y') {
                        foreach ($vm in $allVMS) {
                            if (Get-Powerstate $vm) {
                                Write-Host "[`e[33m*`e[0m] Shutting down $vm..."
                                & $vmrun -T ws stop (Get-VMpath $vm) 
                                Write-Host "[`e[31m-`e[0m] $vm OFF."
                            } else {
                                Write-Host "[`e[31m-`e[0m] $vm is already OFF."
                            }
                        }
                    }
                }
                'Restart' {
                    Write-Host "Restart all machines? (`e[32my`e[0m/`e[31mN`e[0m): " -NoNewLine
                    $opcao = Read-Host
                    if ($opcao -eq 'y') {
                        foreach ($vm in $allVMS) {
                            if (Get-Powerstate $vm) {
                                Write-Host "[`e[33m*`e[0m] Restarting $vm..."
                                & $vmrun -T ws reset (Get-VMpath $vm)
                                Write-Host "[`e[32m+`e[0m] $vm ON."
                            } else {
                                Write-Host "[`e[31m-`e[0m] $vm is OFF."
                            }
                        }
                    }
                }
                'SSH' {
                    Write-Host "[`e[36mINFO`e[0m] Can't SSH into all machines." -NoNewLine
                }
            }
        } else {
            switch ($Action) {
                'Start' {
                    if (Get-Powerstate $Name) {
                        Write-Host "[`e[32m+`e[0m] $Name is already ON."
                    } else {
                        Write-Host "[`e[33m*`e[0m] Starting $Name..."
                        & $vmrun -T ws start (Get-VMpath $Name) nogui
                        Write-Host "[`e[32m+`e[0m] $Name ON."
                    }
                }
                'Status' {
                    if (Get-Powerstate $Name) {
                        Write-Host "[`e[32m+`e[0m] $Name is ON."
                        Write-Host "[`e[36mINFO`e[0m] IP Address:`e[32m" (& $vmrun -T ws getGuestIPAddress (Get-VMpath $Name) -wait)"`e[0m"
                    } else {
                        Write-Host "[`e[31m-`e[0m] $Name is OFF."
                    }
                }
                'Stop' {
                    if (Get-Powerstate $Name) {
                        Write-Host "[`e[33m*`e[0m] Shutting down $Name..."
                        & $vmrun -T ws stop (Get-VMpath $Name)
                        Write-Host "[`e[31m-`e[0m] $Name OFF."
                    } else {
                        Write-Host "[`e[31m-`e[0m] $Name is already OFF."
                    }
                }
                'Restart' {
                    if (Get-Powerstate $Name) {
                        Write-Host "[`e[33m*`e[0m] Restarting $Name..."
                        & $vmrun -T ws reset (Get-VMpath $Name)
                        Write-Host "[`e[32m+`e[0m] $Name ON."
                    } else {
                        Write-Host "[`e[31m-`e[0m] $Name is OFF."
                    }
                }
                'SSH' {
                    if (Get-Powerstate $Name) {
                        $IP = (& $vmrun -T ws getGuestIPAddress (Get-VMpath $Name) -wait)
                        if (Test-Connection -Quiet -ComputerName $IP -TcpPort 22) {
                            if ((Get-Content E:\VMs\myvms.txt).Contains($Name)) {
                                ssh -q joaomarcosth9@$IP
                            } else {
                                Write-Host "[`e[34mSSH`e[0m] $Name is ON at: `e[32m$IP`e[0m"
                                Write-Host "[`e[34mSSH`e[0m] Which user do you want to log in with?"
                                Write-Host "[`e[34mSSH`e[0m] `e[36mUser`e[0m: " -NoNewline
                                $user = Read-Host
                                ssh $user@$IP
                            }
                        } else {
                            Write-Host "[`e[31mSSH`e[0m] Connection refused (Port 22)."
                        }
                    } else {
                        Use-VMrun Start $Name
                        $IP = (& $vmrun -T ws getGuestIPAddress (Get-VMpath $Name) -wait)
                        if (Test-Connection -Quiet -ComputerName $IP -TcpPort 22) {
                            if ((Get-Content E:\VMs\myvms.txt).Contains($Name)) {
                                ssh -q joaomarcosth9@$IP
                            } else {
                                Write-Host "[`e[34mSSH`e[0m] $Name has IP: `e[32m$IP`e[0m"
                                Write-Host "[`e[34mSSH`e[0m] Which user do you want to log in with?"
                                Write-Host "[`e[34mSSH`e[0m] `e[36mUser`e[0m: " -NoNewline
                                $user = Read-Host
                                ssh $user@$IP
                            }
                        } else {
                            Write-Host "[`e[31mSSH`e[0m] Connection refused (Port 22)."
                        }
                    }
                }
            }
        } 
    }
}