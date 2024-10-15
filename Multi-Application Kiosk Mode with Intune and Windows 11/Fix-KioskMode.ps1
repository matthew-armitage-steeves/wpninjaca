<#
.SYNOPSIS
    Sets specified registry settings
.DESCRIPTION
    This script is intended to run as an Intune Remediation remediation script and will set the specified registry settings
    File Name      : Remediate-RegistrySettings.ps1
    Version        : 1.0
    Creation Date  : 2023-08-09
    Author         : Matthew Armitage
    Prerequisite   : PowerShell V5.1
.NOTES
    To create a value for the (default) value in a key, set the RegKey name to $null
    For a REG_MULTI_SZ set the RegKey value to an array eg. @("string1";"string2")
.EXAMPLE
    The only thing needed to be edited in this script to set regkeys are the [RegKey] Objects in the $REGKEYS array.
    These Objects can be re-used (copy and paste) in the Detect-RegistrySettings.ps1 script
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
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon';name="AutoAdminLogon";value="1";type='REG_SZ'}
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon';name="DefaultUserName";value=".\kioskuser0";type='REG_SZ'}
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon';name="IsConnectedAutoLogon";value="0";type='REG_DWORD'}]
    [RegKey]@{hive='HKEY_LOCAL_MACHINE';key='SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon';name="DefaultPassword";value="";type='REG_SZ'}
)   
## Code Execution Area
foreach ($keyobject in $REGKEYS){
    $path = $keyobject.hive+"\"+$keyobject.key
    $registryPath = "registry::"+$path
    if (($keyobject.name -eq "") -and (Test-Path $registryPath)) {
    }
    elseif ([bool](Get-ItemProperty -ErrorAction Ignore -Path $registryPath -Name $keyobject.name)){
        Remove-ItemProperty -Path $registryPath -Name $keyobject.name
    }
    try {
        switch ($keyobject.type) {
            'REG_DWORD' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, $keyobject.value,[Microsoft.Win32.RegistryValueKind]::DWord) }
            'REG_SZ' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, $keyobject.value,[Microsoft.Win32.RegistryValueKind]::String) }
            'REG_BINARY' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, $keyobject.value,[Microsoft.Win32.RegistryValueKind]::Binary) }
            'REG_EXPAND_SZ' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, $keyobject.value,[Microsoft.Win32.RegistryValueKind]::ExpandString) }
            'REG_MULTI_SZ' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, [string[]]$keyobject.value,[Microsoft.Win32.RegistryValueKind]::MultiString) }
            'REG_QWORD' {[microsoft.win32.registry]::SetValue($path, $keyobject.name, $keyobject.value,[Microsoft.Win32.RegistryValueKind]::QWord) }
            Default {}
        }
    }
    catch {
        Write-Error "Registry Settings Failed"
    }
}
