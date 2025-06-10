# 🔎 Entra ID User Report Generator

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Graph API](https://img.shields.io/badge/Microsoft%20Graph-API-green?logo=microsoft)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## 📋 Overview

This PowerShell script exports a comprehensive CSV report of all users in Microsoft Entra ID (formerly Azure AD), enriched with detailed insights from Microsoft Graph. It’s designed for IT admins and security teams who need a **quick, complete, and centralized** view of Entra ID accounts, including:

- ✅ User identity and account metadata
- 🔐 MFA method details by type (Microsoft Authenticator, OATH, FIDO2, etc.)
- 📱 Auth device details (e.g. "iPhone 16 Pro", phone number, email used for MFA)
- 💻 Registered devices associated with each user
- 🛡️ Privileged role memberships
- 🗓️ Password expiration and last change
- 🌍 Usage location, job details, and contact info

---

## 🚀 Features

- Connects to Microsoft Graph with delegated permissions
- Exports detailed user attributes into a clean, ready-to-filter CSV
- Reports key security posture elements:
    - MFA setup + per-method device details (e.g., display name, email, phone)
    - Password policy and sign-in preferences
    - Devices registered to the user
- Tracks and displays runtime duration

---

## 🔧 Requirements

- PowerShell Core 7+
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

| 🧍 Identity & Contact              | 🔐 Security & Authentication                        | 🏢 Organizational Details          | 🌐 Hybrid & Sync Details               |
|----------------------------------|-----------------------------------------------------|-----------------------------------|----------------------------------------|
| Id                               | AccountEnabled                                      | JobTitle                          | OnPremisesSyncEnabled                  |
| DisplayName                      | MicrosoftAuthenticatorDisplayName                  | CompanyName                       | OnPremisesLastSyncDateTime             |
| First name                       | EmailAuthAddress                                   | Department                        | OnPremisesDistinguishedName            |
| Last name                        | SMSPhoneNumber                                     | EmployeeId                        | OnPremisesImmutableId                  |
| UserPrincipalName                | FIDO2DisplayName                                   | EmployeeType                      | OnPremisesSamAccountName               |
| Domain name                      | WindowsHelloEnabled                                | EmployeeHireDate                  | OnPremisesUserPrincipalName            |
| UserType                         | SoftwareOATHEnabled                                | EmployeeLeaveDateTime             | OnPremisesDomainName                   |
| CreatedDateTime                  | AuthenticationMethod                               | ManagerDisplayName                | UsageLocation                          |
| LastPasswordChangeDateTime       | DefaultAuthentication                              | ManagerUPN                        | PreferredDataLocation                  |
| PasswordPolicies                 | LastSignInDateTime                                 | SponsorDisplayName                | Devices                                |
| PreferredLanguage                | LicensesSkuType                                    | SponsorUPN                        |                                        |
| SignInSessionsValidFromDateTime  |                                                   |                                   |                                        |
| MailNickname                     |                                                   |                                   |                                        |
| Mail                             |                                                   |                                   |                                        |
| OtherMails                       |                                                   |                                   |                                        |
| ProxyAddresses                   |                                                   |                                   |                                        |
| ImAddresses                      |                                                   |                                   |                                        |
| AgeGroup                         |                                                   |                                   |                                        |
| ConsentProvidedForMinor          |                                                   |                                   |                                        |
| LegalAgeGroupClassification      |                                                   |                                   |                                        |
| BusinessPhones                   |                                                   |                                   |                                        |
| MobilePhone                      |                                                   |                                   |                                        |
| StreetAddress                    |                                                   |                                   |                                        |
| City                             |                                                   |                                   |                                        |
| State                            |                                                   |                                   |                                        |
| PostalCode                       |                                                   |                                   |                                        |
| Country                          |                                                   |                                   |                                        |

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
