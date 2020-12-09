Function Get-value {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $object,
        [Parameter(Mandatory = $true)]
        [string] $Key
    )
    Process {
        [psobject] $jsondata = $object | ConvertFrom-Json 
        $keys = $key -split '/' 
        $Keys | ForEach-Object {
            if (-not ($jsondata.$_)) {
                Write-output "$object does not have a Key named $_ "
                break
            }
            else {
                $jsondata = $jsondata.$_
            }
        }
        #If Key provided is not the leaf of the json, then output the json value
        if (($jsondata.GetType()).Name -eq 'PSCustomObject' ) {
            $jsondata | convertto-json -Compress
        }
        #If Key provided is leaf of the json, then output the value as string
        if (($jsondata.GetType()).Name -eq 'String' ) {
            $jsondata
        }
    }
}