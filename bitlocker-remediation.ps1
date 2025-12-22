<#
.SYNOPSIS    
Detects and remediates disabled BitLocker encryption.

.DESCRIPTION
Intune policies check compliance on a schedule, leaving gaps where BitLocker could 
stay disabled. This script runs locally to catch and fix the issue immediately 
without waiting for the next policy sync or requiring manual intervention.

.NOTES
Author: Nicholas Clauser
Deployment: Intune Proactive Remediations
Requires: Admin privileges, TPM 

# EncryptionMethod is required (the standard 128-bit encryption will fail compliance due to Intune policy settings)
# TpmProtector is required for automatic key usage on startup
# RecoveryPasswordProtector is required to back up the recovery key to Entra ID

#>

#Requires -RunAsAdministrator

# 1 Check if TPM is available → Exit if missing
# 2 Get BitLocker status on C: drive
# 3 If BitLocker is disabled > Enable with XTS AES 256-bit encryption
# Backup recovery key must be sent to Entra ID > happens automatically with RecoveryPasswordProtector)
# Log result and exit with status code: 0 = success, 1 = failure

# 1 Get TPM state
$tpm = Get-Tpm
if (-not $tpm.TpmReady){
    Write-Error "TPM is disabled - aborting script."
    exit 1
}
Write-Output "TPM is enabled. Proceeding."

# 2 Get BitLocker state
try {
    $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
}
catch {
    Write-Error "C drive not found - aborting script."
    exit 1
}
Write-Output "C drive status is: $($bitlockerStatus.ProtectionStatus)."

# 3 If BitLocker is off, enable it
# See .Notes above for more verbose explanation of parameters
try {
    if ($bitlockerStatus.ProtectionStatus -eq 0){
    Enable-BitLocker -MountPoint "C:" `
        -EncryptionMethod XtsAes256 `
        -TpmProtector `
        -RecoveryPasswordProtector `
        -ErrorAction Stop 
    # Exit if successful
    Write-Output "BitLocker is successfully enabled."
    exit 0
    }
}
catch {
    Write-Error "Failed to enable BitLocker - aborting script."
    # Exit if failure
    exit 1
}

Write-Output "Reached end of script. BitLocker enabled; no changes made."
exit 0
