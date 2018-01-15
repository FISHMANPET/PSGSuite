﻿function Send-GmailMessage {
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $false)]
        [Alias("PrimaryEmail","UserKey","Mail")]
        [ValidateNotNullOrEmpty()]
        [String]
        $From = $Script:PSGSuite.AdminEmail,
        [parameter(Mandatory = $true)]
        [string]
        $Subject,
        [parameter(Mandatory = $false)]
        [string]
        $Body,
        [parameter(Mandatory = $false)]
        [string[]]
        $To,
        [parameter(Mandatory = $false)]
        [string[]]
        $CC,
        [parameter(Mandatory = $false)]
        [string[]]
        $BCC,
        [parameter(Mandatory = $false)]
        [ValidateScript( {Test-Path $_})]
        [string[]]
        $Attachments,
        [parameter(Mandatory = $false)]
        [switch]
        $BodyAsHtml
    )
    Process {
        $User = $From -replace ".*<","" -replace ">",""
        if ($User -ceq 'me') {
            $User = $Script:PSGSuite.AdminEmail
            $From = $User
        }
        elseif ($User -notlike "*@*.*") {
            $User = "$($User)@$($Script:PSGSuite.Domain)"
            $From = $User
        }
        $serviceParams = @{
            Scope       = 'https://mail.google.com'
            ServiceType = 'Google.Apis.Gmail.v1.GmailService'
            User        = $User
        }
        $service = New-GoogleService @serviceParams
        $messageParams = @{
            From                     = $From
            Subject                  = $Subject
            ReturnConstructedMessage = $true
        }
        if ($To) {
            $messageParams.Add("To",@($To))
        }
        if ($Body) {
            $messageParams.Add("Body",@($Body))
        }
        if ($CC) {
            $messageParams.Add("CC",@($CC))
        }
        if ($BCC) {
            $messageParams.Add("BCC",@($BCC))
        }
        if ($Attachments) {
            $messageParams.Add("Attachment",@($Attachments)) 
        }
        if ($BodyAsHtml) {
            $messageParams.Add("BodyAsHtml",$true)
        }
        $raw = New-MimeMessage @messageParams | Convert-Base64 -From NormalString -To WebSafeBase64String
        try {
            $bodySend = New-Object 'Google.Apis.Gmail.v1.Data.Message' -Property @{
                Raw = $raw
            }
            $request = $service.Users.Messages.Send($bodySend,$User)
            Write-Verbose "Sending Message '$Subject' from user '$User'"
            $request.Execute() | Select-Object @{N = 'User';E = {$User}},*
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}