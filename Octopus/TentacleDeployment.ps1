# Installs to default %programfiles(x86)%
msiexec /i Octopus.Tentacle.<version>.msi /quiet

# To determine installation location!
#msiexec INSTALLLOCATION=C:\YourDirectory /i Octopus.Tentacle.<version>.msi /quiet

cd "%programfiles(x86)%\Octopus Deploy\Tentacle"

"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" create-instance --instance "Tentacle" --config "E:\Octopus\Tentacle.config"
"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" new-certificate --instance "Tentacle" --if-blank
"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" configure --instance "Tentacle" --reset-trust
"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" configure --instance "Tentacle" --home "E:\Octopus" --app "E:\Octopus\Applications" --port "10933" --noListen "False"
"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" configure --instance "Tentacle" --trust "7BF6160F4ED1D9DDB98DF07032454B27D7BF308E"
"netsh" advfirewall firewall add rule "name=Octopus Deploy Tentacle" dir=in action=allow protocol=TCP localport=10933
"C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" service --instance "Tentacle" --install --start