﻿
icm $citrix_environment.CDC_6.XENAPP_SERVERS {
	#$citrixprintservice = Get-WmiObject Win32_Service | Where {$_.Name -eq "cpsvc"}
    #sc.exe failure $citrixprintservice.Name reset= 86400 actions= restart/5000/restart/5000/restart/5000
	sc.exe failure cpsvc reset= 86400 actions= restart/5000/restart/5000/restart/5000
	sc.exe failure Imaservice reset= 86400 actions= restart/5000/restart/5000/restart/5000
}