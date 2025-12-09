# Zero-Touch Windows Deployment Implementation

Work in progress.

This project simulates a "Zero-Touch" provisioning workflow for an organization (Clauser Corp). The goal is to take a fresh Win11 VM and have it fully configured, secured, and ready for app deployment automatically after the first sign in.

**Current Status:** Building & Testing

## Tech Stack
* **MDM:** Microsoft Intune (Plan 1)
* **Identity:** Microsoft Entra ID
* **Client:** Windows 11 Enterprise
* **Tools:** PowerShell, Win32 Content Prep Tool

## Implementation Checklist

**Phase 1: Environment**
- [x] obtain m365 business premium tenant
- [x] create dedicated global admin user
- [x] create github repo for asset hosting
- [x] upload corporate branding (`wallpaper.png`) for URL access

**Phase 2: Config & Policy**
- [x] configure device restriction policy (desktop wallpaper lock)
- [ ] setup Win11 enterprise vm (enable vtpm for autopilot)
- [ ] package google chrome enterprise (`.intunewin`)
- [ ] create win32 app deployment profile in intune

**Phase 3: Security & Validation**
- [ ] configure bitlocker silent encryption policy
- [ ] configure compliance policies (require bitlocker + secure boot + possibly TPM)
- [ ] run OOBE deployment tests on vm

## Notes / Asset Links
* **Wallpaper Source:** `https://raw.githubusercontent.com/nicholasclauser/intune-zero-touch-lab/main/wallpaper.png`
