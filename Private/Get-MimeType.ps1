﻿function Get-MimeType {
  param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] 
    [ValidateScript({Test-Path $_})]
    [String]$File 
  )
$res = 'application/unknown' 
try 
    { 
    $rk = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey(($ext = ([IO.FileInfo](($File = cvpa $File))).Extension.ToLower())) 
    } 
finally 
    { 
    if ($rk -ne $null) 
        { 
        if (![String]::IsNullOrEmpty(($cur = $rk.GetValue('Content Type')))) 
            { 
            $res = $cur 
            } 
        $rk.Close() 
        } 
    } 
return $res 
}