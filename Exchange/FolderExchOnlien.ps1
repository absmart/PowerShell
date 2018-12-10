function Load-EWSManagedAPI{
    param(
    ) 
    Begin
    {
        ## Load Managed API dll 
        ###CHECK FOR EWS MANAGED API, IF PRESENT IMPORT THE HIGHEST VERSION EWS DLL, ELSE EXIT
        $EWSDLL = (($(
            Get-ItemProperty -ErrorAction SilentlyContinue -Path Registry::$(Get-ChildItem -ErrorAction SilentlyContinue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Exchange\Web Services'|Sort-Object Name -Descending| Select-Object -First 1 -ExpandProperty Name)).'Install Directory') + "Microsoft.Exchange.WebServices.dll")
        if (Test-Path $EWSDLL)
            {
            Import-Module $EWSDLL
            }
        else
            {
            "$(get-date -format yyyyMMddHHmmss):"
            "This script requires the EWS Managed API 1.2 or later."
            "Please download and install the current version of the EWS Managed API from"
            "http://go.microsoft.com/fwlink/?LinkId=255472"
            ""
            "Exiting Script."
            exit
            }
    }
}
 
function Connect-Exchange{
    param(
        [Parameter(Position=0, Mandatory=$true)] [string]$MailboxName,
        [Parameter(Position=1, Mandatory=$true)] [System.Management.Automation.PSCredential]$Credentials
    ) 
    Begin
         {
        Load-EWSManagedAPI
         
        ## Set Exchange Version 
        $ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010_SP1
           
        ## Create Exchange Service Object 
        $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion) 
           
        #Credentials 
        $creds = New-Object System.Net.NetworkCredential($Credentials.UserName.ToString(),$Credentials.GetNetworkCredential().password.ToString()) 
        $service.Credentials = $creds      
 
        #CAS URL hardcoded for Exchange Online
           
        $uri=[system.URI] "https://outlook.office365.com/EWS/Exchange.asmx" 
        $service.Url = $uri   
         
        if(!$service.URL){
            throw "Error connecting to EWS"
        }
        else
        {      
            return $service
        }
    }
}
 
function Create-Folder{
    param(
        [Parameter(Position=0, Mandatory=$true)] [string]$MailboxName,
        [Parameter(Position=1, Mandatory=$true)] [System.Management.Automation.PSCredential]$Credentials,
        [Parameter(Position=2, Mandatory=$true)] [String]$NewFolderName
    ) 
    Begin
     {
        $service = Connect-Exchange -MailboxName $MailboxName -Credentials $Credentials
        $NewFolder = new-object Microsoft.Exchange.WebServices.Data.Folder($service) 
        $NewFolder.DisplayName = $NewFolderName
        $NewFolder.FolderClass = "IPF.Note"
         
        # Bind to the MsgFolderRoot folder 
        $folderid= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$MailboxName)  
        $EWSParentFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$folderid)
 
        #Define Folder Veiw Really only want to return one object 
        $fvFolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(1) 
        #Define a Search folder that is going to do a search based on the DisplayName of the folder 
        $SfSearchFilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,$NewFolderName) 
        #Do the Search 
        $findFolderResults = $service.FindFolders($EWSParentFolder.Id,$SfSearchFilter,$fvFolderView) 
        if ($findFolderResults.TotalCount -eq 0){ 
            Write-host ("Folder Doesn't Exist") -ForegroundColor Yellow 
            $NewFolder.Save($EWSParentFolder.Id) 
            Write-host ("Folder Created") -ForegroundColor Green  
        } 
        else{ 
            Write-error ("Folder already Exist with that Name")
        } 
         
         
     }
}
 
# Define tenant credentials
$Credentials = Get-Credential
 
# Define mailboxes that need the archive folder created
# Get all mailboxes
$Mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.Name -notlike "DiscoverySearchMailbox*"}
 
# Or import a list of mailboxes from .txt
# $Mailboxes = Get-Content C:\Temp\Mailboxes.txt
 
# Create the folder
ForEach ($MailboxName in $Mailboxes) {
    Write-host "Processing $MailboxName" -ForegroundColor Yellow
    Create-Folder -MailboxName $MailboxName.PrimarySmtpAddress -NewFolderName Archive -Credentials $Credentials
    }