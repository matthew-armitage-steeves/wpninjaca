<#
.SYNOPSIS
    Checks for specified registry settings
.DESCRIPTION
    This script is intended to run as an Intune Remediation Detection script and will detect the presence of specified registry settings
    File Name      : Detect-RegistrySettings.ps1
    Version        : 1.0
    Creation Date  : 2023-08-09
    Author         : Matthew Armitage
    Prerequisite   : PowerShell V5.1
.NOTES
    To detect a value for the (default) value in a key, set the RegKey name to $null
    For a REG_MULTI_SZ set the RegKey value to an array eg. @("string1";"string2")
.EXAMPLE
    The only thing needed to be edited in this script to detect regkeys are the [RegKey] Objects in the $REGKEYS array.
    These Objects can be re-used (copy and paste) in the Remediate-RegistrySettings.ps1 script
    Example Regkey object:
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Clipboard';name="IsClipboardSignalProducingFeatureAvailable";value="1";type='REG_DWORD'}
#>
if (![bool]([Environment]::Is64BitProcess)){
    Write-Error "Not run in 64-Bit PowerShell. Change Remediation Settings to use 64-Bit"
    exit 99
}
class RegKey {
    [string]$hive
    [string]$key
    [string]$name
    $value
    [string]$type;
}
$REGKEYS = @(
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Clipboard';name="IsClipboardSignalProducingFeatureAvailable";value="1";type='REG_DWORD'}
)
## Code Execution Area
$missingREGKEYS = @()
foreach ($keyobject in $REGKEYS){
    switch ($keyobject.hive) {
        'HKEY_LOCAL_MACHINE' { $path = "registry::HKEY_LOCAL_MACHINE\"+$keyobject.key }
        'HKEY_CURRENT_USER' { $path = "registry::HKEY_CURRENT_USER\"+$keyobject.key }
        'HKEY_USERS' { $path = "registry::HKEY_USERS\"+$keyobject.key }
        'HKEY_CURRENT_CONFIG' { $path = "registry::HKEY_CURRENT_CONFIG\"+$keyobject.key }
        'HKEY_CLASSES_ROOT' { $path = "registry::HKEY_CLASSES_ROOT\"+$keyobject.key }
        Default {}
    }
    $name = $keyobject.name
    if (($keyobject.type -eq 'REG_MULTI_SZ') -and (Test-Path -Path $path) -and ($null -ne (Get-ItemProperty -Path $path).$name)) {
        if ([bool](Compare-Object -ErrorAction Ignore (Get-ItemProperty -Path $path).$name $keyobject.value)){
            $missingREGKEYS += $keyobject
        }
    }
    elseif ((Test-Path -Path $path) -and ("" -eq $keyobject.name)){
        if ([string](Get-ItemProperty -Path $path)."(default)" -ne $keyobject.value){
            $missingREGKEYS += $keyobject
        }
    }
    elseif ((Test-Path -Path $path) -and ((Get-ItemProperty -Path $path).$name -eq $keyobject.value)) {}
    else {    
        $missingREGKEYS += $keyobject
    }   
}
if ($missingREGKEYS.count -gt 0) {
    $missingkey = foreach ($missingregkey in $missingREGKEYS){
        Write-Output "Hive:"$missingregkey.hive"Path:"$missingregkey.key"Name:"$missingregkey.name"Value:"$missingregkey.value`n
    }
    $count = $missingREGKEYS.count
    Write-Output "Registry Keys missing or incorrect:$count" $missingREGKEYS
    exit 1
} else {
    Write-Output "All Registry Items Found"
    exit 0
}

