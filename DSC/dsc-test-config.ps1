configuration webserver
{
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
        File Test3
        {
            Ensure = "Absent"
            DestinationPath = "C:\testgreen3.txt"
            Type = "File"
            Contents = "Updated the ps1 and reuploaded."
        }
        File Test4
        {
            Ensure = "Present"
            DestinationPath = "C:\testgreen4.txt"
            Type = "File"
            Contents = "Updated the ps1 and reuploaded."
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
        File Test3
        {
            Ensure = "Absent"
            DestinationPath = "C:\testred3.txt"
            Type = "File"
            Contents = "Updated the ps1 and reuploaded."
        }
        File Test4
        {
            Ensure = "Present"
            DestinationPath = "C:\testgreen4.txt"
            Type = "File"
            Contents = "Updated the ps1 and reuploaded."
        }
    }
}
webserver