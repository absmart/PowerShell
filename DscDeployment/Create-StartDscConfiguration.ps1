param(
    [string] $DomainName,
    [pscredential] $Credential = (Get-Credential),
    [string] $OutPath
)

configuration InitialDscConfig
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $Credential 
    )

    Import-DscResource -ModuleName xComputerManagement

    if($DomainName -ne $null){

        xComputerManagement DomainJoin
        {
            Name = $DomainName
            DomainName = $DomainName
            Credential = $Credential
        }
    }
    
    File DeploymentCleanup
    {
        Ensure = "Absent"
        DependsOn = ""
    }
}

InitialDscConfig -OutputPath $OutPath -Credential $Credential