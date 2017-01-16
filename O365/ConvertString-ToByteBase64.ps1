$enc = [system.Text.Encoding]::UTF8
$string1 = "DEF456" 
$data1 = $enc.GetBytes($string1) 

# Create a New SHA1 Crypto Provider 
$sha = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 

# Now hash and display results 
$result1 = $sha.ComputeHash($data1)
[System.Convert]::ToBase64String($result1)