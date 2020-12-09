#Requires -Module @{ ModuleName = 'pester'; ModuleVersion = '5.1.0' }

#Importing funtion 
Set-Location $PSScriptRoot
. .\Get-Value.ps1

$obj = '{"x":{"y":{"z":"a"}}}'
$key = 'x/y/z' 
$obj1 = '{"x":{"y":{"z":"a"}}}'
$key1 = 'x'
Describe "Get-Value Testing" {
    Context "when object  = $obj and Key = $key are provided" {
        It "The return should be 'a'" {
            Get-Value -object $obj -Key $key  | Should -Be 'a'
        }
    }
    Context "when object  = $obj1 and Key = $key1 are provided" {
        It "The return should be '{`"y`":{`"z`":`"a`"}}'" {
            Get-Value -object $obj1 -Key $key1  | Should -Be '{"y":{"z":"a"}}'
        }
    }
}