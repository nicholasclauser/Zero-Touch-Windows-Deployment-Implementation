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
    # don't assume the OS escrowed the key. back it up to Entra ID explicitly and verify.
    $vol = Get-BitLockerVolume -MountPoint "C:"
    $recovery = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } | Select-Object -First 1
    if (-not $recovery) {
        Write-Error "No recovery password protector found after enabling BitLocker."
        exit 1
    }
    try {
        BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $recovery.KeyProtectorId -ErrorAction Stop
        Write-Output "Recovery key escrowed to Entra ID."
    }
    catch {
        Write-Error "Failed to back up recovery key to Entra ID: $($_.Exception.Message)"
        exit 1
    }

    # only report success once encryption is actually under way
    $vol = Get-BitLockerVolume -MountPoint "C:"
    if ($vol.VolumeStatus -in 'EncryptionInProgress','FullyEncrypted') {
        Write-Output "BitLocker enabled and encrypting (status: $($vol.VolumeStatus))."
        exit 0
    }
    Write-Error "BitLocker did not start encrypting (status: $($vol.VolumeStatus))."
    exit 1
    }
}
catch {
    Write-Error "Failed to enable BitLocker - aborting script."
    # Exit if failure
    exit 1
}

# reached here means ProtectionStatus was not 0 (already on, suspended, or unknown)
if ($bitlockerStatus.ProtectionStatus -eq 1) {
    Write-Output "BitLocker already on. No action needed."
    exit 0
}

Write-Error "BitLocker not in a compliant state (ProtectionStatus: $($bitlockerStatus.ProtectionStatus)). Flagging for remediation."
exit 1
