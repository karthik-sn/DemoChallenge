Function Get-AzureMetadata {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $query
    )
    Process {
        if (-not ($query)) { 
            #in case specific data is NOT queried, output the entire JSON output
            Invoke-RestMethod -Headers @{"Metadata" = "true" } -Method GET -Uri http://169.254.169.254/metadata/instance?api-version=2020-09-01 | ConvertTo-Json
        }
        else {
            #in case specific data is queried, output the data based on the query
            $data = Invoke-RestMethod -Headers @{"Metadata" = "true" } -Method GET -Uri http://169.254.169.254/metadata/instance?api-version=2020-09-01
            $datapath = $query -split '/'
            $datapath | ForEach-Object {
                if (-not ($data.$_)) {
                    Write-output "Meta Data does not have a property named $query "
                    break
                }
                else {
                    $data = $data.$_
                }
            }
            #If query provided is not the leaf of the json, then output the json value
            if (($data.GetType()).Name -eq 'PSCustomObject' ) {
                $data | convertto-json
            }
            else {
                #If query provided is leaf of the json, then output the value as string
                $data
            }
        }
    }
}

#eg 1: get metadata of a VM without any specific query
Get-AzureMetadata
#eg 2: get metadata with specific query
$query = 'compute/storageProfile'
Get-AzureMetadata -query $query