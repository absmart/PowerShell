configuration webserver
{
    Import-DscResource –ModuleName ’PSDesiredStateConfiguration’ 
    
    Node green
    {
        File Test
        {
            Ensure = "Absent"
            DestinationPath = "C:\testgreen.txt"
            Type = "File"
            Contents = "Hello from Azure Automation DSC!"
        }
        
        File Test2
        {
            Ensure = "Present"
            DestinationPath = "C:\testgreen2.txt"
            Type = "File"
            Contents = "Hello from Azure Automation DSC!"
        }

        WindowsFeature Web-Server
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
    Node red
    {
        File Test
        {
            Ensure = "Absent"
            DestinationPath = "C:\testred.txt"
            Type = "File"
            Contents = "Hello from Azure Automation DSC!"
        }

        File Test2
        {
            Ensure = "Present"
            DestinationPath = "C:\testred2.txt"
            Type = "File"
            Contents = "Hello from Azure Automation DSC!"
        }

        WindowsFeature Web-Server
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}
webserver