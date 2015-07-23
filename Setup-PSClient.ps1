param(
    $SCRIPTS_HOME_Path
)

[Environment]::SetEnvironmentVariable("SCRIPTS_HOME", $SCRIPTS_HOME_Path, "Machine")
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force