# DemoChallenge
<h1 class="code-line" data-line-start=0 data-line-end=1 ><a id="DemoChallenge_0"></a>DemoChallenge</h1>
<p class="has-line-data" data-line-start="2" data-line-end="9">1 - 3-Tier Architecure creation<br>
- Architecture diagram : <a href="https://github.com/karthik-sn/DemoChallenge/blob/master/3-tier%20implementation/Architecture%20Diagram.png">https://github.com/karthik-sn/DemoChallenge/blob/master/3-tier implementation/Architecture Diagram.png</a><br>
- Subnets have been used to steamline network communication<br>
- Only one public IP used for the fron end Load Balancer, all other and Load Balancers and NICs are only usng private IP asigned by the subnet<br>
- Azure SQL with DR in a differnt region created with a failover group mechanism to enable automatic failover in case the primay region goes down<br>
- Load balancing rules are used to route to specific ports from incoming to backend<br>
- Azure Availability Sets have been used to get more SLA in terms of the uptime of 99.95%</p>
<p class="has-line-data" data-line-start="10" data-line-end="15">2 - Get-value Function<br>
- Powershell  v5 used to create a function<br>
- Pester v5.1.0 used to create sample test cases<br>
- Usage:<br>
Get-Value -object ‘{“x”:{“y”:{“z”:“a”}}}’  -Key ‘x/y/z’</p>
<p class="has-line-data" data-line-start="16" data-line-end="25">3 - Get-AzureMetadata<br>
- To be run on any Azure VM to fetch metadata for that VM<br>
- Has an option to run qurey to filter output<br>
- Usage:<br>
#eg 1: get metadata of a VM without any specific query<br>
Get-AzureMetadata<br>
#eg 2: get metadata with specific query<br>
$query = ‘compute/storageProfile’<br>
Get-AzureMetadata -query $query</p>
