function Get-SPListViaWebService {
    param(
    [string] $url, [string] $list, [string] $view = $null 
    )

$listData = @()

$service = New-WebServiceProxy (Get-WebServiceURL -url $url) -Namespace List -UseDefaultCredential

$FieldsWS = $service.GetList( $list )
$Fields = $FieldsWS.Fields.Field | where { $_.Hidden -ne "TRUE"} | Select DisplayName, StaticName -Unique
$data = $service.GetListItems( $list, $view, $null, $null, $null, $null, $null )

foreach( $item in $data.data.row ) {
	$t = new-object System.Object
	foreach( $field in $Fields ) {
		$StaticName = "ows_" + $field.StaticName
		$DisplayName = $field.DisplayName
		if( $item.$StaticName -ne $nul ) {
			$t | add-member -type NoteProperty -name $DisplayName.ToString() -value $item.$StaticName
		}
	}
	$listData += $t
}

return $listData

}

function WriteTo-SPListViaWebService ( [String] $url, [String] $list, [HashTable] $Item, [String] $TitleField )
{
	begin {
		$service = New-WebServiceProxy (Get-WebServiceURL -url $url) -Namespace List -UseDefaultCredential
	}
	process {

		$xml = @"
			<Batch OnError='Continue' ListVersion='1' ViewName='{0}'>  
				<Method ID='1' Cmd='New'>
					{1}
				</Method>  
			</Batch>  
"@   

		$listInfo = $service.GetListAndView($list, "")   

		foreach ($key in $item.Keys) {
			$value = $item[$key]
			if( -not [String]::IsNullOrEmpty($TitleField) -and $key -eq $TitleField ) {
				$key = "Title"
			}
			$listItem += ("<Field Name='{0}'>{1}</Field>`n" -f $key, [system.web.httputility]::HtmlEncode($value))
		}   
  
		$batch = [xml]($xml -f $listInfo.View.Name,$listItem)   
				
		$response = $service.UpdateListItems($listInfo.List.Name, $batch)   
		$code = [int]$response.result.errorcode   
	
 		if ($code -ne 0) {   
			Write-Warning "Error $code - $($response.result.errortext)"     
		}
	}
	end {
		
	}
}

function Update-SPListViaWebService ( [String] $url, [String] $list, [int] $id, [HashTable] $Item, [String] $TitleField )
{
	begin {
		$service = New-WebServiceProxy (Get-WebServiceURL -url $url) -Namespace List -UseDefaultCredential
		$listItem = [String]::Empty
	}
	process {

		$xml = @"
			<Batch OnError='Continue' ListVersion='1' ViewName='{0}'>  
				<Method ID='{1}' Cmd='Update'>
				<Field Name='ID'>{1}</Field>
					{2}
				</Method>  
			</Batch>  
"@   

		$listInfo = $service.GetListAndView($list, "")   

		foreach ($key in $item.Keys) {
			$value = $item[$key]
			if( -not [String]::IsNullOrEmpty($TitleField) -and $key -eq $TitleField ) {
				$key = "Title"
			}
			$listItem += ("<Field Name='{0}'>{1}</Field>`n" -f $key, [system.web.httputility]::HtmlEncode($value))  
		}   
  
		$xml = ($xml -f $listInfo.View.Name,$id, $listItem)  
		$batch = [xml] $xml

		try { 		
			$response = $service.UpdateListItems($listInfo.List.Name, $batch)   
			$code = [int]$response.result.errorcode   
	
			if ($code -ne 0) {   
				Write-Warning "Error $code - $($response.result.errortext)"     
			} 
		}
		catch [System.Exception] {
			Write-Error ("Update failed with - " +  $_.Exception.ToString() )
		}
	}
	end {
		
	}
}