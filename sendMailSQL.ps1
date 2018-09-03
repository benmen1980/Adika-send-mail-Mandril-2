param 
( 
     
    [string]$ToEmail = "ToEmail",
	[string]$Subject = "Subject",
	[string]$CDES = "CustomerName",
	[string]$PAYCODE = "PayCode",
	[string]$QPRICE = "Qprice",
    [string]$INTCREDIT = "InternalCredit",
    #added by Sebastian Boruga
    [string]$CUST="CustID"
    #end of addition
)

#added by Sebastian Boruga

#this function reads the config file and stores entries in global variables
function readConfigFile{
    #test if config file exists; otherwise write to log
    if(Test-Path P:\bin.95\sendmail\config.cfg){
        #if config file exists, check if all needed entries are supplied
        $configFileContents = Get-Content P:\bin.95\sendmail\config.cfg

        try{
            #store config file entries in global variables
            $global:db_host = $configFileContents[3].Substring(8,$configFileContents[3].Length-8)
            $global:db_user = $configFileContents[4].Substring(8,$configFileContents[4].Length-8)
            $global:db_pass = $configFileContents[5].Substring(8,$configFileContents[5].Length-8)
            $global:db_name = $configFileContents[6].Substring(8,$configFileContents[6].Length-8)
        }
        catch{
            echo 'Error parsing config file.'
            exit
        }
    }
    else{
        echo 'Config file not found.'
        exit
    }
}

#defining connection
function defineConnection{
    $global:connection = New-Object System.Data.SQLClient.SQLConnection
    $connectionString = "Server="+$db_host+";Database="+$db_name+";User ID ="+$db_user+";Password="+$db_pass+";"
    $global:connection.ConnectionString = $connectionString
}

#run query and store result in $CustomerSecription variable
function runQuery{
    try{
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $connection
    $SQLQuery = "select CUSTDES FROM CUSTOMERS WHERE CUST = "+ $CUST
    $Command.CommandText = $SQLQuery

    $Connection.Open()
    $reader = $Command.ExecuteReader()
    $reader.Read()
    $global:CustomerDescription = [System.Text.Encoding]::GetEncoding("UTF-16");

    $global:CustomerDescription = $reader["CUSTDES"]
    $reader.Close()
    $Connection.Close()
    }
    catch{
        $string = "Error -> "+$Error[0].Exception
        exit
    }
}

readConfigFile
defineConnection
runQuery
$string = "Customer description: "+$CustomerDescription
echo $string

#end of addition

$encSubject = [System.Text.Encoding]::Unicode
$MySubject= $encSubject.GetBytes($Subject)
$custdes = [System.Text.Encoding]::GetEncoding("UTF-16");

$AnotherSubject = $Subject;
#$Subject = Get-Content -Encoding UTF8 $Subject

$json = @{"key"="Vwsa3zPspMu6Yrlv0jr4Lg";
 "id"="bd7b30d0539e415b9685abd2898c7985";
 }|ConvertTo-Json
 
 
 $json = @"
 {
    "key": "Vwsa3zPspMu6Yrlv0jr4Lg",
    "template_name": "Adikastyle",
    "template_content": [
        {
            "name": "example name",
            "content": "example content"
        }
    ],
    "message": {
        "subject": "$AnotherSubject",
        "from_email": "info@adikastyle.com",
        "from_name": "Adika style RMA system",
        "to": [
            {
                "email": "$ToEmail",
                "name": "Nati",
                "type": "to"
            }
        ],
        "merge_vars": [
            {
                "rcpt": "$ToEmail",
                "vars": [
                    {
                        "name": "CDES",
                        "content": "$CustomerDescription"
                    },
					{
                        "name": "PAYCODE",
                        "content": "$PAYCODE"
                    },
					{
                        "name": "QPRICE",
                        "content": "$QPRICE"
                    },
					{
                        "name": "INTCREDIT",
                        "content": "$INTCREDIT"
                    }
                ]
            }
        ]
    },
    "async": false,
    "ip_pool": "Main Pool",
    "send_at": "2018-01-01 00:00:00"
}
"@
 
#write-host $CustomerDescription;

 Invoke-RestMethod -Uri  mandrillapp.com/api/1.0/messages/send-template.json -Method POST -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -ContentType "application/json"

#write-host "Press any key to continue..."
#[void][System.Console]::ReadKey($true)


