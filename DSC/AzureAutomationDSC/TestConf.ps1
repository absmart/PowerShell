configuration ModuleTest {

Import-DscResource -ModuleName cSmbShare

    node Name {
        File Web
            {
                Ensure = "Present"
                DestinationPath = "C:\Web"
                Type = "Directory"
            }

            cSmbShare Web
            {
                Ensure = "Present"
                Name = "Web"
                Path = "C:\Web"
                DependsOn = "[File]Web"
                ReadAccess = "Everyone"
            }
    }
}