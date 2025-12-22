# Technical Documentation: Zero-Touch BitLocker Remediation

**Script:** `bitlocker-remediation.ps1`

**Context:** Intune Proactive Remediations (Runs as SYSTEM)

**Goal:** Detect unencrypted system drives and enforce XTS-AES-256 encryption silently.

---

## Problems Encountered and Their Fixes

### 1. The Output "String vs Integer" Trap
**Problem:** The script ran successfully (Exit Code 0), but the drive remained unencrypted. Manual verification with `manage-bde -status` showed `Protection Status: Off`.

**Root Cause:** The PowerShell console "prints" the `ProtectionStatus` enum (integer `0`) as the word "Off".
**Reality:**
* **Java Intuition:** Coming from a Java background, I treated the console output as a String.
* **PowerShell Reality:** The underlying value is an Integer (`0`). Comparing `if ($Status -eq "Off")` failed silently because `0` is not equal to `"Off"`.
**Fix:** Changed logic to compare against the raw integer: `if ($bitlockerStatus.ProtectionStatus -eq 0)`.

### 2. Legacy WMI vs. Modern Cmdlets
**Problem:** Initial research pointed to 2014-era solutions using `Get-WmiObject Win32_TPM`. This is more advanced than necessary, and relies on older protocols.

**Fix:** I simply used `Get-Tpm` cmdlet instead, which is recommended by Microsoft Learn. Specifically used the `.TpmReady` boolean property for a cleaner, "fail-fast" check compatible with Windows 11.

### 3. Compliance Risk: XTS-AES-256 vs AES-256
**Problem:** The default BitLocker encryption style (even on modern Windows 11 devices) is 128-bit. Microsoft Learn documentation examples often references `-EncryptionMethod Aes256`. 

**Risk:** Modern Intune Security Baselines typically require **XTS-AES-256**. If a device is encrypted with the older standard, my Intune policy will flag it as "Non-Compliant" immediately.

**Fix:** Explicitly defined `-EncryptionMethod XtsAes256` to ensure the device meets strict compliance standards upon encryption.

### 4. Zero-Touch Silence
**Problem:** The script needed to run invisibly to the user (Zero Touch).
**Fix:** Included the `-TpmProtector` parameter. While redundant for security (since we already verify TPM is enabled), this parameter is required to suppress user prompts during boot. Without it, the "Zero Touch" experience breaks.

---

## Development Journey

This automation was built to close the gap between an Intune policy sync and immediate compliance needs.

### Logical Flow Design
I established three distinct phases for the script to ensure idempotency:
1.  **Pre-flight:** Check TPM status (Fail fast if missing).
2.  **Status Check:** Query `Get-BitLockerVolume` on the C: drive.
3.  **Remediation:** If (and only if) status is `0` (Off), trigger encryption.

### Handling the Recovery Key
A major concern was ensuring keys weren't lost during local script execution.
* **Concern:** I initially debated between using `RecoveryKeyProtector` (Legacy/USB .bek files) and `RecoveryPasswordProtector` (Modern/Entra ID). The `RecoveryKeyProtector` was specifically used in lots of PowerShell examples on Microsoft Learn.
* **Solution:** Using `-RecoveryPasswordProtector` generates the actual 48-digit BitLocker key. Because the device is Entra-joined, Windows automatically reads this event and stores the key in the cloud.

### Script Requirements
* **OS:** Windows 10/11 Enterprise or Pro
* **Privileges:** Administrator (SYSTEM context when deployed via Intune)
* **Hardware:** TPM 2.0 or higher
* **Modules:** `BitLocker`, `TrustedPlatformModule`
* **Intune Exit Codes:**
    * `0`: Success (BitLocker is enabled, or the device is already compliant)
    * `1`: Failure (Possibly due to TPM missing, BitLocker not being enabled)