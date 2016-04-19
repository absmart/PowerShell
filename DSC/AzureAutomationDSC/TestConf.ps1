configuration ModuleTest 
{
    node AzureDscVm {
        File Web
            {
                Ensure = "Present"
                DestinationPath = "C:\Web"
                Type = "Directory"
            }
            
            WindowsFeature Web
            {
                Ensure = "Present"
                Name = "Web-Server"
            }            
    }
}