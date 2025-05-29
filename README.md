# 🔎 Entra ID User Report Generator

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Graph API](https://img.shields.io/badge/Microsoft%20Graph-API-green?logo=microsoft)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## 📋 Overview

This PowerShell script exports a comprehensive CSV report of all users in Microsoft Entra ID (formerly Azure AD), enriched with detailed insights from Microsoft Graph. It’s designed for IT admins and security teams who need a **quick, complete, and centralized** view of Entra ID accounts, including:

- ✅ User identity and account metadata
- 🔐 MFA method enrollment (Authenticator, OATH, FIDO2, etc.)
- 🛡️ Privileged role memberships
- 🎫 Access package assignments
- 🗓️ Password expiration and last change
- 🌍 Usage location, job details, and contact info

> The script supports both standard and premium tenants. It adjusts dynamically depending on licensing (e.g., SignInActivity).

---

## 🚀 Features

- Connects to Microsoft Graph with delegated permissions
- Exports detailed user attributes into a clean, ready-to-filter CSV
- Integrates with Identity Governance to include Access Packages (via `EntitlementManagement.Read.All`)
- Reports key security posture elements:
  - MFA setup
  - Password policy
  - Admin roles
  - Risk state
- Tracks and displays runtime duration
- Progress bar + real-time processing status (e.g., `123/1000 - Processing john.doe@contoso.com`)

---

## 📦 Output Example (Sample)

| Display Name | User Principal Name                        | Domain Name                  | Email Address                          | Job Title       | Department | Company     | Office | Employee ID | Mobile     | Phone     | Street       | City     | Postal Code | State | Country | User Type | On-Premises Sync | Immutable ID (On-Prem) | Account Status | Account Created on | Last Successful Sign-in | Licensed | Default MFA Method | MFA Status | Email Auth | FIDO2 | Auth App | Auth Lite | Phone MFA | OATH | TAP | WHFB | Password Never Expires | Last Password Change Date | Usage Location | Assigned Licenses                                              | Is Admin (Privileged Role) | Sign-in Risk State | Access Packages         |
|--------------|--------------------------------------------|------------------------------|----------------------------------------|-----------------|------------|-------------|--------|--------------|------------|-----------|--------------|----------|--------------|-------|---------|------------|------------------|--------------------------|----------------|---------------------|--------------------------|----------|---------------------|------------|-------------|--------|-----------|------------|-----------|------|-----|------|--------------------------|-----------------------------|----------------|------------------------------------------------------------------|-----------------------------|---------------------|--------------------------|
| Adele Vance  | [AdeleV@M365x82780588.OnMicrosoft.com](mailto:AdeleV@M365x82780588.OnMicrosoft.com) | M365x82780588.OnMicrosoft.com | AdeleV@M365x82780588.OnMicrosoft.com | Cloud Engineer  | Engineering | Contoso Ltd | Paris  | 12345        | +33612345678 | +33512345678 | 5 Rue Azure | Bordeaux | 33000        | FR    | France  | Member     | Disabled         | None                     | Enabled        | 2025-02-21 12:05    | 2025-05-15 20:34         | Yes      | push                | Enabled    | -           | -      | ✅        | -          | -         | -    | -   | -    | No                       | 2025-05-15 20:32             | NL             | 7e74bd05..., 3271cf8e...                                      | No                          | -                   | AP_CONTOSO_DEVS          |
| Alex Wilber  | [AlexW@M365x82780588.OnMicrosoft.com](mailto:AlexW@M365x82780588.OnMicrosoft.com)  | M365x82780588.OnMicrosoft.com | AlexW@M365x82780588.OnMicrosoft.com  | Marketing Lead  | Marketing   | Contoso Ltd | Lyon   | 54321        | +33687654321 | +33587654321 | 7 Rue Rouge | Lyon     | 69000        | FR    | France  | Member     | Enabled          | abcdefg123456789         | Enabled        | 2024-11-03 08:23    | 2025-05-10 17:45         | No       | -                   | Disabled   | -           | -      | -         | -          | -         | -    | -   | -    | Yes                      | 2025-05-10 17:45             | NL             | None                                                             | Security Reader             | -                   | None                     |

---
## 🔧 Requirements

- PowerShell 5.1+ or Core 7+
- Microsoft Graph PowerShell SDK (`Install-Module Microsoft.Graph -Scope CurrentUser`)
- Admin account with delegated permissions to Microsoft Graph
- Required Graph scopes:
  - `User.Read.All`
  - `Directory.Read.All`
  - `AuditLog.Read.All`
  - `UserAuthenticationMethod.Read.All`
  - `EntitlementManagement.Read.All`
  - `Organization.Read.All`
  - `IdentityRiskyUser.Read.All`

---

## 🛠️ Usage

```powershell
.\export_entraid_usrs.ps1
```
---

## 📂 Fields Included
Display Name, UPN, Email, Phone, Job Title, Company

Manager's Display Name and UPN

Account Created On, Password Last Changed

MFA Details (per method type)

Admin Role Membership

Access Package Names

Sign-in Risk State

Sync Status and Immutable ID

Usage Location, Country, Address

---

## 🧠 Tips
Run in PowerShell Core (7.x) for faster performance

Use Windows Terminal with dark theme for fancier progress UX 😎

Use Excel/Power BI to filter, pivot, or visualize the exported CSV

---

## 📄 License
This project is licensed under the MIT License. Use it, fork it, automate with it.

---

## ❤️ Contributions
Open an issue or PR to suggest improvements or report bugs. Let’s make Microsoft Entra reporting easy, elegant, and extensible!
