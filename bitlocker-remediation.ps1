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
Requires: Admin privileges, TPM 2.0

#>

#Requires -RunAsAdministrator

# Check if TPM is available → Exit if missing

# Get BitLocker status on C: drive

# If BitLocker is disabled → Enable with AES 256-bit encryption

# Backup recovery key must be sent to Entra ID

# Log result and exit with status code for Intune (0 = success, 1 = failure)