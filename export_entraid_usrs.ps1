# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All", "Organization.Read.All", "Directory.Read.All", "IdentityRiskyUser.Read.All", "EntitlementManagement.Read.All" -NoWelcome

# Start timing
$startTime = Get-Date

# Timestamp for the CSV file
$LogDate = Get-Date -f yyyyMMddhhmm
$Csvfile = Join-Path -Path $PSScriptRoot -ChildPath "EntraIDUsers_$LogDate.csv"

# Check if EntraID Premium is available
$hasPremium = (Get-MgSubscribedSku).ServicePlans.ServicePlanName -contains "AAD_PREMIUM"
Write-Host "Entra ID Premium subscription detected: $hasPremium" -ForegroundColor Cyan

# Retrieve all Access Package assignments once
$allAssignments = @()
try {
    $response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/accessPackageAssignments?`$expand=accessPackage,accessPackageAssignmentPolicy"
    $allAssignments = $response.value
} catch {
    Write-Host "Failed to retrieve Access Package assignments."
}

# Define user properties to pull
$commonProperties = @(
    'Id','GivenName','Surname','DisplayName','UserPrincipalName','Mail','JobTitle',
    'Department','CompanyName','OfficeLocation','ProxyAddresses','CreatedDateTime',
    'EmployeeID','MobilePhone','BusinessPhones','StreetAddress','City','PostalCode',
    'State','Country','UserType','onPremisesSyncEnabled','OnPremisesImmutableId',
    'AccountEnabled','AssignedLicenses'
)

$propertyParams = @{
    All            = $true
    ExpandProperty = 'manager'
    Property       = if ($hasPremium) { @('SignInActivity') + $commonProperties } else { $commonProperties }
}

$users = Get-MgUser @propertyParams
$totalUsers = $users.Count
$Report = [System.Collections.Generic.List[Object]]::new()

# Process each user
foreach ($index in 0..($totalUsers - 1)) {
    $user = $users[$index]

    # Show live progress
    Write-Host "$($index + 1)/$totalUsers - Processing $($user.UserPrincipalName)"
    Write-Progress -Activity "Exporting Users to CSV" -Status "Progress..." -PercentComplete ((($index + 1) / $totalUsers) * 100)

    $managerDN  = $user.Manager?.AdditionalProperties?.DisplayName
    $managerUPN = $user.Manager?.AdditionalProperties?.UserPrincipalName

    $ReportLine = [PSCustomObject]@{
        "ID"                           = $user.Id
        "First name"                   = $user.GivenName
        "Last name"                    = $user.Surname
        "Display name"                 = $user.DisplayName
        "User principal name"          = $user.UserPrincipalName
        "Domain name"                  = $user.UserPrincipalName.Split('@')[1]
        "Email address"                = $user.Mail
        "Job title"                    = $user.JobTitle
        "Manager display name"         = $managerDN
        "Manager user principal name"  = $managerUPN
        "Department"                   = $user.Department
        "Company"                      = $user.CompanyName
        "Office"                       = $user.OfficeLocation
        "Employee ID"                  = $user.EmployeeID
        "Mobile"                       = $user.MobilePhone
        "Phone"                        = $user.BusinessPhones -join ','
        "Street"                       = $user.StreetAddress
        "City"                         = $user.City
        "Postal code"                  = $user.PostalCode
        "State"                        = $user.State
        "Country"                      = $user.Country
        "User type"                    = $user.UserType
        "On-Premises sync"             = if ($user.onPremisesSyncEnabled) { "Enabled" } else { "Disabled" }
        "Immutable ID (On-Prem)"       = if ($user.OnPremisesImmutableId) { $user.OnPremisesImmutableId } else { "None" }
        "Account status"               = if ($user.AccountEnabled) { "Enabled" } else { "Disabled" }
        "Account Created on"           = $user.CreatedDateTime
        "Last successful sign in"      = if ($hasPremium -and $user.SignInActivity?.LastSuccessfulSignInDateTime) { $user.SignInActivity.LastSuccessfulSignInDateTime } else { "Unavailable" }
        "Licensed"                     = if ($user.AssignedLicenses.Count -gt 0) { "Yes" } else { "No" }
        "DefaultMFAMethod"             = "-"
        "MFA status"                   = "-"
        "Email authentication"         = "-"
        "FIDO2 authentication"         = "-"
        "Microsoft Authenticator App"  = "-"
        "Microsoft Authenticator Lite" = "-"
        "Phone authentication"         = "-"
        "Software Oath"                = "-"
        "Temporary Access Pass"        = "-"
        "Windows Hello for Business"   = "-"
        "Password Never Expires"       = "-"
        "Last Password Change Date"    = "-"
        "Usage Location"               = "-"
        "Assigned Licenses"            = "-"
        "Is Admin (Privileged Role)"   = "-"
        "Sign-in Risk State"           = "-"
        "Access Packages"              = "-"
    }

    try {
        $details = Get-MgUser -UserId $user.Id -Property PasswordPolicies, lastPasswordChangeDateTime, UsageLocation
        $ReportLine."Password Never Expires" = if ($details.PasswordPolicies -notmatch "DisablePasswordExpiration") { "No" } else { "Yes" }
        $ReportLine."Last Password Change Date" = $details.lastPasswordChangeDateTime
        $ReportLine."Usage Location" = $details.UsageLocation
    } catch {}

    try {
        $skus = $user.AssignedLicenses | ForEach-Object { $_.SkuId }
        $ReportLine."Assigned Licenses" = if ($skus.Count -gt 0) { $skus -join ", " } else { "None" }
    } catch {}

    try {
        $roles = Get-MgUserMemberOf -UserId $user.Id -All | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.directoryRole" }
        $ReportLine."Is Admin (Privileged Role)" = if ($roles.DisplayName) { $roles.DisplayName -join ', ' } else { "No" }
    } catch {}

    try {
        $riskyUser = Get-MgRiskyUser -UserId $user.Id -ErrorAction Stop
        $ReportLine."Sign-in Risk State" = $riskyUser.RiskState
    } catch {}

    try {
        $DefaultMFAUri = "https://graph.microsoft.com/beta/users/$($user.Id)/authentication/signInPreferences"
        $DefaultMFAMethod = Invoke-MgGraphRequest -Uri $DefaultMFAUri -Method GET
        $ReportLine.DefaultMFAMethod = $DefaultMFAMethod.userPreferredMethodForSecondaryAuthentication ?? "Not set"
    } catch {}

    try {
        $MFAData = Get-MgUserAuthenticationMethod -UserId $user.Id
        foreach ($method in $MFAData) {
            switch ($method.AdditionalProperties["@odata.type"]) {
                "#microsoft.graph.emailAuthenticationMethod"                  { $ReportLine."Email authentication" = $true; $ReportLine."MFA status" = "Enabled" }
                "#microsoft.graph.fido2AuthenticationMethod"                  { $ReportLine."FIDO2 authentication" = $true; $ReportLine."MFA status" = "Enabled" }
                "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                    if ($method.AdditionalProperties["deviceTag"] -eq 'SoftwareTokenActivated') {
                        $ReportLine."Microsoft Authenticator App" = $true
                    } else {
                        $ReportLine."Microsoft Authenticator Lite" = $true
                    }
                    $ReportLine."MFA status" = "Enabled"
                }
                "#microsoft.graph.phoneAuthenticationMethod"                  { $ReportLine."Phone authentication" = $true; $ReportLine."MFA status" = "Enabled" }
                "#microsoft.graph.softwareOathAuthenticationMethod"          { $ReportLine."Software Oath" = $true; $ReportLine."MFA status" = "Enabled" }
                "#microsoft.graph.temporaryAccessPassAuthenticationMethod"   { $ReportLine."Temporary Access Pass" = $true; $ReportLine."MFA status" = "Enabled" }
                "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" { $ReportLine."Windows Hello for Business" = $true; $ReportLine."MFA status" = "Enabled" }
            }
        }
    } catch {}

    try {
        $userAPs = $allAssignments | Where-Object { $_.targetId -eq $user.Id }
        if ($userAPs.Count -gt 0) {
            $ReportLine."Access Packages" = $userAPs | ForEach-Object { $_.accessPackage.displayName } | Sort-Object -Unique | Join-String -Separator ", "
        } else {
            $ReportLine."Access Packages" = "None"
        }
    } catch {
        $ReportLine."Access Packages" = "Error"
    }

    $Report.Add($ReportLine)
}

# End timing
$endTime = Get-Date
$elapsed = $endTime - $startTime

Write-Progress -Activity "Exporting Users" -Completed
$Report | Sort-Object "Display name" | Export-Csv -Path $Csvfile -NoTypeInformation -Encoding UTF8
Write-Host "`n✅ Entra ID user export completed. File saved at: $Csvfile" -ForegroundColor Green
Write-Host "Total time: $($elapsed.Minutes) minutes and $($elapsed.Seconds) seconds." -ForegroundColor Cyan
