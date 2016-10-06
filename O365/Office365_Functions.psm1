
function Connect-MSOnline {
  [CmdletBinding()]
  param(
    $User,
    $Password = (Read-Host)
  )

	    #Write-Host "Connecting to Microsoft Online..."
	    try {
	      Connect-MsolService -Credential $Office365credentials -ErrorAction Stop
	    }
	    catch {
	      Write-Host "FAILURE connecting to Office 365" -ForegroundColor Red
	      Return
	    }
	}
}

function Global:Connect-365
{
  <#
		.Synopsis
		Instantiates a remote connection to Office 355
		REMEMBER to use Disconnect-365 when finished!
		
		.Example	
		Connect-365
	#>

  [CmdletBinding()]
  param()

  begin {}

  process {
		if ($Office365.Connected -eq $True) { Return }

    Write-Host "Connecting to Office 365 ..."
    $LiveCred = Get-Credential

    try {
      $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionURI https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection -ErrorAction Stop
      Import-PSSession $Session -DisableNameChecking
    }
    catch {
      Write-Host "FAILURE Conencting to Office 365"
      Return
    }

		$Office365.Connected = $True
    Clear-Host
    Write-Host "Connected to Office 365"
    Get-PSSession
    Write-Debug â€œ`$Session: $Sessionâ€
		Write-Host ""
		Return
  }
}

function Global:Disconnect-365
{
  <#
		.Synopsis
		Disconnects a remote connection to Office 355
		
		.Example	
		Disconnect-365
	#>

  [CmdletBinding()]
  param()

  begin {}

  process {

    # Disconnect all remote sessions

    $Session = Get-PSSession

    if ($Session -ne $null) {
      #Get-PSSession | Format-Table
      #Write-Debug $DebugSession
      Remove-PSSession $Session
      Write-Host "Disconencted from Office 365"
    }
	
		$Office365.Connected = $False
  }
}

function Global:Export-365-MB-List
{
  <#
		.Synopsis
		Exports mailbox data to a CSV file.  
		
		.Example	
		Export-365-MB-List Csvfile
		
		.Parameter Csvfile
		CSV file name for output
	#>

  [CmdletBinding(DefaultParameterSetName = "CSVFile")]
  param(
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™CSV Output fileâ€™)]
    [string]$CSVFile = ""
  )

  begin {}

  process {
    if ($CSVFile -eq "") {
      $Date = Get-Date -Format yyyyMMdd

      $CSVFile = $Date + "_mbox_list.csv"
    }

    Write-Debug $CSVFile

    Connect-365
    if ($Office365.Connected -eq $False) { Return }

		Write-Host "Exporting mailbox listing"

    Get-Mailbox -ResultSize unlimited | `
       Select displayname,name,userprincipalname,alias,* -ea SilentlyContinue | `
       Sort-Object displayname | `
       Export-Csv $CSVFile -notype

    Write-Host "Mailbox listing CSV file $CSVfile completed"
  }
}

function Global:Export-365-MB-Stats
{
  <#
		.Synopsis
		Exports mailbox data statistics to a CSV file.  
		This takes a while to execute against every account
		
		.Example	
		Export-365-MB-Stats Csvfile
		
		.Parameter Csvfile
		CSV file name for output
	#>

  [CmdletBinding(DefaultParameterSetName = "CSVFile")]
  param(
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™CSV Output fileâ€™)]
    [string]$CSVFile = ""
  )

  begin {}

  process {
    if ($CSVFile -eq "") {
      $Date = Get-Date -Format yyyyMMdd

      $CSVFile = $Date + "_mbox_stats.csv"
    }

    Write-Debug $CSVFile

		Connect-365
    if ($Office365.Connected -eq $False) { Return }

    Clear-Host
    Write-Host "Export Mailbox statistics.  This can take a while."

    Write-Host "Getting list of mailboxes..."
    $Mailboxes = Get-Mailbox -ResultSize unlimited | Sort-Object displayname | Select userprincipalname
    $RecordCount = $Mailboxes.Length
    $Count = 0
    $Stats = $Mailboxes | ForEach-Object {
      $PctComplete = [math]::Round(($Count / $RecordCount) * 100,1)
      $User = $_.userprincipalname
      Write-Progress -Activity "Getting mailbox statistics..." `
         -PercentComplete $PctComplete -CurrentOperation "$PctComplete% complete" -Status "Processing $User"
      Get-MailboxStatistics $_.userprincipalname | `
         Select displayname,lastlogontime,totalitemsize,itemcount,originatingserver,* -ErrorAction SilentlyContinue
      $Count += 1
    }

    $Stats | Export-Csv $CSVFile -notype
    Write-Host "Mailbox statistics CSV file $CSVfile completed"
  }
}

function Global:Export-365-MB-Stats-Archive
{
  <#
		.Synopsis
		Exports archive mailbox data statistics to a CSV file.  
		This takes a while to execute against every account
		
		.Example	
		Export-365-MB-Stats-Archive Csvfile
		
		.Parameter Csvfile
		CSV file name for output
	#>

  [CmdletBinding(DefaultParameterSetName = "CSVFile")]
  param(
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™CSV Output fileâ€™)]
    [string]$CSVFile = ""
  )

  begin {}

  process {
    if ($CSVFile -eq "") {
      $Date = Get-Date -Format yyyyMMdd

      $CSVFile = $Date + "_mbox_stats_archive.csv"
    }

    Write-Debug $CSVFile

    Connect-365
    if ($Office365.Connected -eq $False) { Return }

    Clear-Host
    Write-Host "Export Archive Mailbox statistics.  This can take a while."

    Write-Host "Getting list of mailboxes..."
    $Mailboxes = Get-Mailbox -Archive -ResultSize unlimited | Sort-Object displayname | Select userprincipalname
    $RecordCount = $Mailboxes.Length
    $Count = 0
    $Stats = $Mailboxes | ForEach-Object {
      $PctComplete = [math]::Round(($Count / $RecordCount) * 100,1)
      $User = $_.userprincipalname
      Write-Progress -Activity "Getting mailbox statistics..." `
         -PercentComplete $PctComplete -CurrentOperation "$PctComplete% complete" -Status "Processing $User"
      Get-MailboxStatistics -Archive $_.userprincipalname | `
         Select displayname,lastlogontime,totalitemsize,itemcount,originatingserver,* -ea SilentlyContinue
      $Count += 1
    }

    $Stats | Export-Csv $CSVFile -notype

    #    Get-Mailbox -ResultSize unlimited | `
    #       Get-MailboxStatistics -Archive | `
    #       Select displayname,lastlogontime,totalitemsize,itemcount,originatingserver,* -ea SilentlyContinue | `
    #       Sort-Object displayname | `
    #       Export-Csv $CSVFile -notype

    Write-Host "Mailbox statistics CSV file $CSVfile completed"
  }
}

function Global:Export-365-Licenses
{
  <#
		.Synopsis
		Exports Office 365 license usage to a CSV file.  
		
		.Example	
		Export-365-Licenses Csvfile
		
		.Parameter Csvfile
		CSV file name for output
	#>

  [CmdletBinding(DefaultParameterSetName = "CSVFile")]
  param(
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™CSV Output fileâ€™)]
    [string]$CSVFile = ""
  )

  begin {}

  process {
    if ($CSVFile -eq "") {
      $Date = Get-Date -Format yyyyMMdd

      $CSVFile = $Date + "_licenses_365.csv"
    }

    Connect-MSOnline
    if ($Office365.ConnectedMSOnline -eq $False) { Return }
		#Connect-365

    # Get a list of all licences that exist within the tenant
    $licensetype = Get-MsolAccountSku | Where { $_.ConsumedUnits -ge 1 } | Sort-Object accountskuid

    $headerstring = '"DisplayName","UserPrincipalName","AccountSku"'
    Out-File -FilePath $CSVFile -InputObject $headerstring -Encoding UTF8

    # Loop through all licence types found in the tenant
    foreach ($license in $licensetype)
    {
      # Build and write the Header for the CSV file
      #$headerstring = '"DisplayName","UserPrincipalName","AccountSku"'

      foreach ($row in $($license.ServiceStatus)) {
        # Build header string
        switch -wildcard ($($row.ServicePlan.servicename))
        {
          "EXC*" { $thisLicence = "Exchange Online" }
          "MCO*" { $thisLicence = "Lync Online" }
          "LYN*" { $thisLicence = "Lync Online" }
          "OFF*" { $thisLicence = "Office Profesional Plus" }
          "SHA*" { $thisLicence = "Sharepoint Online" }
          "*WAC*" { $thisLicence = "Office Web Apps" }
          "WAC*" { $thisLicence = "Office Web Apps" }
          default { $thisLicence = $row.ServicePlan.servicename }
        }
        $headerstring = ($headerstring + ',"' + $thisLicence + '"')
      }

      #Out-File -FilePath $CSVFile -InputObject $headerstring -Encoding UTF8 -Append

      Write-Host ("Gathering users with the following subscription: " + $license.accountskuid)

      # Gather users for this particular AccountSku
      $users = Get-MsolUser -All | Where { $_.isLicensed -eq "True" -and $_.licenses[0].accountskuid.ToString() -eq $license.accountskuid }

      # Loop through all users and write them to the CSV file
      foreach ($user in $users) {
        Write-Debug ("Processing " + $user.displayname)
        $datastring = ('"' + $user.displayname + '","' + $user.userprincipalname + '","' + $Office365.SkuInfo.SkuTypes.Item($user.licenses[0].AccountSku.SkuPartNumber) + '"')
        foreach ($row in $($user.licenses[0].ServiceStatus)) {
          # Build data string
          #$datastring = ($datastring + ',"' + $($row.provisioningstatus) + '"')
        }
        Out-File -FilePath $CSVFile -InputObject $datastring -Encoding UTF8 -Append
      }
    }
    Write-Host "License CSV file $CSVFile completed"
  }
}

function Global:Remove-365-License
{
  <#
		.Synopsis
		Removes standard and enterprise licenses from user from Office 365
		
		.Example	
		Remove-365-License UPN@domain.com confirm_yn
		
		.Parameter UserPrincipalName
		User principal name (primary email address)
	#>

  [CmdletBinding(DefaultParameterSetName = "UserPrincipalName")]
  param(
    [Parameter(Mandatory = $True,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™UserPrincipalName (UPN@domain.com)â€™)]
    [string]$UserPrincipalName = "",

    [Parameter(Mandatory = $True,
      ValueFromPipeline = $False,
      Position = 1,
      HelpMessage = â€™Confirm (Y/N)â€™)]
    [string]$Confirm = ""
  )

  begin {}

  process {
    if ($Confirm -ne "Y") {
      Write-Warning "License removal NOT confirmed.  Exiting."
      return
    }

    Connect-MSOnline
    if ($Office365.ConnectedMSOnline -eq $False) { Return }

    $AccountInfo = Get-MsolUser -UserPrincipalName $UserPrincipalName | Select licenses

    Write-Host ""
    Write-Host "Removing licenses for: $UserPrincipalName" -ForegroundColor red -BackgroundColor white

    foreach ($License in $AccountInfo.licenses) {
      $Sku = $License.accountskuid
      Write-Host $Sku
      Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -RemoveLicenses $Sku
    }
    Write-Host ""
  }
}

function Global:Get-365-License
{
  <#
		.Synopsis
		Get license type for user from Office 365
		
		.Example	
		Get-365-License UPN@domain.com
		
		.Parameter UserPrincipalName
		User principal name (primary email address)
	#>

  [CmdletBinding(DefaultParameterSetName = "UserPrincipalName")]
  param(
    [Parameter(Mandatory = $True,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™UserPrincipalName (UPN@domain.com)â€™)]
    [string]$UserPrincipalName = ""
  )

  begin {}

  process {
    Connect-MSOnline
    if ($Office365.ConnectedMSOnline -eq $False) { Return }

    $AccountInfo = Get-MsolUser -UserPrincipalName $UserPrincipalName | Select licenses
    Write-Host ""
    Write-Host "Licenses for: $UserPrincipalName"
    foreach ($License in $AccountInfo.licenses) {
      $Sku = $Office365.SkuInfo.SkuTypes[$License.AccountSku.SkuPartNumber]
      Write-Host $Sku
    }
    Write-Host ""
	}
}

function Global:Terminate-365-User
{
  <#
		.Synopsis
		Convert to shared mailbox
		Enable litigation hold for the user
		Remove 365 licenses for the user
		
		.Example	
		Terminate-365-User UPN@Domain.com confirm_yn
		
		.Parameter UserPrincipalName
		User principal name (primary email address)
	#>

  [CmdletBinding(DefaultParameterSetName = "UserPrincipalName")]
  param(
    [Parameter(Mandatory = $True,
      ValueFromPipeline = $False,
      Position = 0,
      HelpMessage = â€™UserPrincipalName (UPN@Facs.Org)â€™)]
    [string]$UserPrincipalName = "",

    [Parameter(Mandatory = $True,
      ValueFromPipeline = $False,
      Position = 1,
      HelpMessage = â€™Confirm (Y/N)â€™)]
    [string]$Confirm = ""
  )

  begin {}

  process {
    if ($Confirm -ne "Y") {
      Write-Warning "Termination NOT confirmed.  Exiting."
      return
    }

    Connect-MSOnline
    if ($Office365.ConnectedMSOnline -eq $False) { Return }
    Connect-365
    if ($Office365.Connected -eq $False) { Return }

    Write-Host ""
    Write-Host "Performing Office 365 termination for $UserPrincipalName" -ForegroundColor red -BackgroundColor white

		Write-Host "Convert user to E3 license"
    $AddE3 = $True
    $AccountInfo = Get-MsolUser -UserPrincipalName $UserPrincipalName
    foreach ($License in $AccountInfo.Licenses) {
			if ($Office365.SkuInfo.SkuTypes[$License.AccountSku.SkuPartNumber] -eq "E3") { 
				$AddE3 = $False
			}
			else {
				Write-Host "Removing" $License.AccountSkuId
				Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -RemoveLicenses $License.AccountSkuId
			}
		}		

		if ($AddE3 -eq $True) {
			Write-Host "Adding" $Office365.SkuInfo.SkuIdE3
			Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $Office365.SkuInfo.SkuIdE3
		}		

    $HoldSearch = "TH-" + $UserPrincipalName
    Write-Host "Add In-Place Hold for $UserPrincipalName using $HoldSearch"
    $InPlaceHoldEnabled = $False
    $TryCount = 0
    while ($InPlaceHoldEnabled -eq $False -and $TryCount -le 5) {
    	New-MailboxSearch $HoldSearch -SourceMailboxes $UserPrincipalName -InPlaceHoldEnabled $True -ea SilentlyContinue | Out-Null
	    $TermHold = Get-Mailboxsearch $HoldSearch -ea SilentlyContinue
	    if ($TermHold -ne $Null) {  	
	    	$InPlaceHoldEnabled = $True
			}
			if ($TermHold -eq $Null -and $TryCount -lt 5) {
				Countdown 30 "Waiting for In-Place Hold to be available"
				Write-Host "Retry In-Place Hold for $UserPrincipalName using $HoldSearch"
			}
			$TryCount += 1
    }

	  Write-Host ""
		
		if ($InPlaceHoldEnabled -eq $False) {
			Write-Warning "In-Place Hold for $UserPrincipalName failed.  Exiting."
			Return
		}
		else {
			Write-Host "In-Place Hold for $UserPrincipalName set"
		}

		Write-Host "Convert mailbox to shared"
		Set-Mailbox $UserPrincipalName -Type shared

    Write-Host "Remove E3 license for: $UserPrincipalName"
    $AccountInfo = Get-MsolUser -UserPrincipalName $UserPrincipalName
    foreach ($License in $AccountInfo.Licenses) {
			Write-Host "Removing" $License.AccountSkuId
      Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -RemoveLicenses $License.AccountSkuId
    }

    Write-Host ""
  }
}

################################################################ï»¿
#	Module loading
################################################################ï»¿

# Module dependencies
Import-Module MSOnline

# Check if loaded already.  Do NOT reinitialize on multiple loads of module
if ($Global:Office365 -eq $null) {
	$VersionTable = @{
		Version="1.00"
		LastModified="9/22/2015"
		ModifiedBy="Adam Devino"
		Copyright="N/A"
	}
	$SkuTypes = @{
	  "ENTERPRISEWITHSCAL" = "E4"
	  "ENTERPRISEPACKLRG" = "E3"
	  "ENTERPRISEPACK" = "E3"
	  "DESKLESSPACK" = "K1"
	  "DESKLESSWOFFPACK" = "K2"
	  "LITEPACK" = "P1"
	  "EXCHANGESTANDARD" = "E0"
	  "STANDARDPACK" = "E1"
	  "STANDARDWOFFPACK" = "E2"
	  "STANDARDPACK_STUDENT" = "A1"
	  "STANDARDWOFFPACKPACK_STUDENT" = "A2"
	  "ENTERPRISEPACK_STUDENT" = "A3"
	  "ENTERPRISEWITHSCAL_STUDENT" = "A4"
	  "STANDARDPACK_FACULTY" = "A1"
	  "STANDARDWOFFPACKPACK_FACULTY" = "A2"
	  "ENTERPRISEPACK_FACULTY" = "A3"
	  "ENTERPRISEWITHSCAL_FACULTY" = "A4"
	  "ENTERPRISEPACK_B_PILOT" = "PE"
	  "STANDARD_B_PILOT" = "PB"
	}

	$Global:Office365 = New-Object -TypeName System.Object
	
	# Global state variables
	Add-Member -InputObject $Office365 -MemberType NoteProperty -Name Connected -Value $False
	Add-Member -InputObject $Office365 -MemberType NoteProperty -Name ConnectedMSOnline -Value $False
	Add-Member -InputObject $Office365 -MemberType NoteProperty -Name VersionTable -Value $VersionTable

	$SkuInfo = New-Object -TypeName System.Object
	Add-Member -InputObject $SkuInfo -MemberType NoteProperty -Name SkuDomain -Value "facs"
	Add-Member -InputObject $SkuInfo -MemberType NoteProperty -Name SkuIdE3 -Value ($SkuInfo.SkuDomain + ":ENTERPRISEPACK")
	Add-Member -InputObject $SkuInfo -MemberType NoteProperty -Name SkuIdE1 -Value ($SkuInfo.SkuDomain + ":STANDARDPACK")
	Add-Member -InputObject $SkuInfo -MemberType NoteProperty -Name SkuTypes -Value $SkuTypes
	Add-Member -InputObject $Office365 -MemberType NoteProperty -Name SkuInfo -Value $SkuInfo

	# Powershell exiting handler.  Disconnect from Office 365
	Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action `
	{
		Disconnect-365
	}
}

Write-Host "Office-365 extensions loaded"
if ($PSVersionTable.PSVersion.Major -lt 3) {
	Write-Warning ">> Powershell upgrade recommended <<"
}