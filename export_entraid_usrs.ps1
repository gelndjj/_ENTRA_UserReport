$properties = @(
    "Id",
    "DisplayName",
    "Surname",
    "GivenName",
    "UserPrincipalName",
    "UserType",
    "CreatedDateTime",
    "LastPasswordChangeDateTime",
    "PasswordPolicies",
    "PreferredLanguage",
    "SignInSessionsValidFromDateTime",
    "JobTitle",
    "CompanyName",
    "Department",
    "EmployeeId",
    "EmployeeType",
    "EmployeeHireDate",
    "EmployeeLeaveDateTime",
    "Manager",
    "StreetAddress",
    "City",
    "State",
    "PostalCode",
    "Country",
    "BusinessPhones",
    "MobilePhone",
    "Mail",
    "OtherMails",
    "ProxyAddresses",
    "ImAddresses",
    "Mailnickname",
    "AgeGroup",
    "ConsentProvidedForMinor",
    "LegalAgeGroupClassification",
    "AccountEnabled",
    "UsageLocation",
    "PreferredDataLocation",
    "OnPremisesSyncEnabled",
    "OnPremisesLastSyncDateTime",
    "OnPremisesDistinguishedName",
    "OnPremisesImmutableId",
    "OnPremisesSamAccountName",
    "OnPremisesUserPrincipalName",
    "OnPremisesDomainName",
    "SignInActivity",
    "onPremisesImmutableId")

$CSVproperties = @(
    # Identity section
    "Id",
    "DisplayName",
    @{Name="First name"; Expression={$_.GivenName}},
    @{Name="Last name"; Expression={$_.Surname}},
    "UserPrincipalName",
    @{Name="Domain name"; Expression = { $_.UserPrincipalName.Split('@')[1] }},
    "UserType",
    "CreatedDateTime",
    "LastPasswordChangeDateTime",
    @{Name="LicensesSkuType";Expression={[string]::join(";", ($_.LicensesSkuType))}},
    "PasswordPolicies",
    "PreferredLanguage",
    "SignInSessionsValidFromDateTime",
    # Job Information section
    "JobTitle",
    "CompanyName",
    "Department",
    "EmployeeId",
    "EmployeeType",
    "EmployeeHireDate",
    "EmployeeLeaveDateTime",
    "ManagerDisplayName",
    "ManagerUPN",
    "SponsorDisplayName",
    "SponsorUPN",
    # Contact Information
    "StreetAddress",
    "City",
    "State",
    "PostalCode",
    "Country",
    @{Name="BusinessPhones"; Expression = { ($_.BusinessPhones -join " ; ") }},
    "MobilePhone",
    "Mail",
    @{Name="OtherMails";Expression={[string]::join(" ; ", ($_.OtherMails))}},
    @{Name="ProxyAddresses";Expression={[string]::join(" ; ", ($_.ProxyAddresses))}},
    @{Name="ImAddresses";Expression={[string]::join(" ; ", ($_.ImAddresses))}},
    "Mailnickname",
    # Parental controls
    "AgeGroup",
    "ConsentProvidedForMinor",
    "LegalAgeGroupClassification",
    # Settings
    "AccountEnabled",
    "UsageLocation",
    "PreferredDataLocation",
    # On-premises
    "OnPremisesSyncEnabled",
    "OnPremisesLastSyncDateTime",
    "OnPremisesDistinguishedName",
    "OnPremisesImmutableId",
    "OnPremisesSamAccountName",
    "OnPremisesUserPrincipalName",
    "OnPremisesDomainName",
    # Authentication methods
    "MFA status",
    "Email authentication",
    "FIDO2 authentication",
    "Microsoft Authenticator App",
    "Microsoft Authenticator Lite",
    "Phone authentication",
    "Software Oath",
    "Windows Hello for Business",
    @{Name="LastSignInDateTime";Expression={$_.SignInActivity.LastSuccessfulSignInDateTime}}
    )

#Requires -Version 7

Connect-MgGraph

# Start timing
$startTime = Get-Date

# Timestamp for the CSV file
$LogDate = Get-Date -f yyyyMMddhhmm
$Csvfile = Join-Path -Path $PSScriptRoot -ChildPath "EntraIDUsers_$LogDate.csv"

Write-Output "Retrieving all users..."
$users = Get-MgUser -All -Property $properties

$usersDetails = [System.Collections.Concurrent.ConcurrentBag[System.Object]]::new()
$length = $users.length
$i = 0
$batchSize = 4

Write-Output "Batch Creation..."

$batches = [System.Collections.Generic.List[pscustomobject]]::new()
for ($i = 0; $i -lt $users.Length; $i += $batchSize) {
    $end = $i + $batchSize - 1
    if ($end -ge $users.Length) { $end = $users.Length }
    $index = $i * 3


    $requests = $users[$i..($end)] | ForEach-Object {
        @{
            'Id'     = "$($PSItem.Id):manager"
            'Method' = 'GET'
            'Url'    = "users/{0}/manager" -f $PSItem.Id 
        },
        @{
            'Id'     = "$($PSItem.Id):sponsor"
            'Method' = 'GET'
            'Url'    = "users/{0}/sponsors" -f $PSItem.Id 
        },
        @{
            'Id'     = "$($PSItem.Id):license"
            'Method' = 'GET'
            'Url'    = "users/{0}/licenseDetails" -f $PSItem.Id 
        },
        @{
            'Id'     = "$($PSItem.Id):authenticationMethods"
            'Method' = 'GET'
            'Url'    = "users/{0}/authentication/methods" -f $PSItem.Id 
        },
        @{
            'Id'     = "$($PSItem.Id):authenticationPreference"
            'Method' = 'GET'
            'Url'    = "users/{0}/authentication/SignInPreferences" -f $PSItem.Id 
        }
    }

    $batches.Add(@{
        'Method'      = 'Post'
        'Uri'         = 'https://graph.microsoft.com/beta/$batch'
        'ContentType' = 'application/json'
        'Body'        = @{
            'requests' = @($requests)
        } | ConvertTo-Json
    })
}

Write-Output "Sending requests" 

$batches | ForEach-Object -Parallel {
    $responses = $using:usersDetails
    $request = Invoke-MgGraphRequest @PSItem
    $request.responses | ForEach-Object {$responses.Add([pscustomobject]@{
            'UserId' = $PSItem.Id.Split(":")[0]
            'requesttype' = $PSItem.Id.Split(":")[1]
            'body' = $PSItem.body 
        })}
}

$usersDetails = $usersDetails | Group-Object -Property UserId -AsHashTable

Write-Output "Processing requests" 

foreach ($user in $users){
    $DaySinceLastCo = ($user.SignInActivity.LastSuccessfulSignInDateTime - $(Get-Date)).Days
    if ($usersDetails.ContainsKey($user.Id)){
        
        $authDetails = @{
            "MFA status"                   = "-"
            "Email authentication"         = "-"
            "FIDO2 authentication"         = "-"
            "Microsoft Authenticator App"  = "-"
            "Microsoft Authenticator Lite" = "-"
            "Phone authentication"         = "-"
            "Software Oath"                = "-"
            "Windows Hello for Business"   = "-"
        }

        $authMethods = $($usersDetails[$user.Id] | Where { $_.requesttype -eq "authenticationMethods" }).body.value

        if ($authMethods.Count -gt 0) {
            $authDetails["MFA status"] = "Enabled"
        }

        foreach ($method in $authMethods) {
            $odataType = $method.'@odata.type'
            switch ($odataType) {
                "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                    $authDetails["Microsoft Authenticator App"] = $method.displayName
                }
                "#microsoft.graph.emailAuthenticationMethod" {
                    $authDetails["Email authentication"] = $method.emailAddress
                }
                "#microsoft.graph.phoneAuthenticationMethod" {
                    $authDetails["Phone authentication"] = $method.phoneNumber
                }
                "#microsoft.graph.fido2AuthenticationMethod" {
                    $authDetails["FIDO2 authentication"] = $method.model
                }
                "#microsoft.graph.softwareOathAuthenticationMethod" {
                    $authDetails["Software Oath"] = "Configured"
                }
                "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
                    $authDetails["Windows Hello for Business"] = "Configured"
                }
            }
        }

        foreach ($key in $authDetails.Keys) {
            $user | Add-Member -MemberType NoteProperty -Name $key -Value $authDetails[$key] -Force
        }
        }
        }

        $user | Add-Member -MemberType NoteProperty -Name ManagerUPN `
            -Value $($($usersDetails[$user.Id] | where {$_.requesttype -eq "manager"}).body.userPrincipalName)

        $user | Add-Member -MemberType NoteProperty -Name SponsorUPN `
            -Value $(($($usersDetails[$user.Id] | where {$_.requesttype -eq "sponsor"}).body.value)[0].userPrincipalName)

        $user | Add-Member -MemberType NoteProperty -Name ManagerDisplayName `
            -Value $($($usersDetails[$user.Id] | Where { $_.requesttype -eq "manager" }).body.displayName)

        $user | Add-Member -MemberType NoteProperty -Name SponsorDisplayName `
            -Value $($($usersDetails[$user.Id] | Where { $_.requesttype -eq "sponsor" }).body.value[0].displayName)

        $user | Add-Member -MemberType NoteProperty -Name LicensesSkuType `
            -Value $($($usersDetails[$user.Id] | where {$_.requesttype -eq "license"}).body.value | select -expandproperty SkuPartNumber)

        $user | Add-Member -MemberType NoteProperty -Name "MFA status" -Value $(if ($authenticationType.Count -gt 0) { "Enabled" } else { "Disabled" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Email authentication" -Value $(if ($authenticationType -contains "Email") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "FIDO2 authentication" -Value $(if ($authenticationType -contains "Fido2") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Microsoft Authenticator App" -Value $(if ($authenticationType -contains "MicrosoftAuthenticator") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Microsoft Authenticator Lite" -Value $(if ($authenticationType -contains "TemporaryAccessPass") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Phone authentication" -Value $(if ($authenticationType -contains "SMS") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Software Oath" -Value $(if ($authenticationType -contains "SoftwareOath") { "Yes" } else { "No" }) -Force
        $user | Add-Member -MemberType NoteProperty -Name "Windows Hello for Business" -Value $(if ($authenticationType -contains "Windows Hello") { "Yes" } else { "No" }) -Force

    if ($user.OnPremisesSyncEnabled -eq $True){
        $user.EmployeeLeaveDateTime = $user.OnPremisesExtensionAttributes.ExtensionAttribute1
    }


Disconnect-MgGraph

Write-Output "Writing CSV"
$users | Select-Object -Property $CSVproperties | Export-Csv -Path $Csvfile -Delimiter ';' -NoTypeInformation -Encoding UTF8

# End timing
$endTime = Get-Date
$elapsed = $endTime - $startTime

Write-Host "Entra ID user export completed. File saved at: $Csvfile" -ForegroundColor Green
Write-Host "Total time: $($elapsed.Minutes) minutes and $($elapsed.Seconds) seconds." -ForegroundColor Cyan
