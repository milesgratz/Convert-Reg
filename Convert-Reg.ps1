Function Convert-Reg {

<#
.DESCRIPTION
  Script to convert Registry (.reg) files to .bat

.PARAMETERS
  Path (Location of .reg file to convert)

.EXAMPLE
  Convert-Reg -Path "C:\temp\Registry.reg"
  Convert-Reg -Path "C:\temp\Registry.reg" -Force    # overwrites reg keys

.AUTHOR
  Miles Gratz (serveradventures.com)

.DATE
  03/21/2015
#>

Param (
    [parameter(Mandatory=$True,Position=1)]
      [string]$Path,
    [switch]$Force
    )
    
    # VERIFY PATH PARAMETER AND CONVERT TO OBJECT
    Try {$PathObj = Get-Item $Path  -ErrorAction Stop}
    Catch {Write-Host "[ERROR] Path is inaccessible. Function aborting..." -ForegroundColor Red; Exit }
    
    # STORE .REG FILE TO VARIABLE 
    Try {$Content = Get-Content $PathObj.FullName -ErrorAction Stop}
    Catch {Write-Host "[ERROR] Path is inaccessible. Function aborting..." -ForegroundColor Red; Exit }
    
    # FIND ALL KEYS (LINES THAT START WITH LEFT BRACKET)
    $Keys = $Content | Select-String -AllMatches "^\["
    
    # CREATE EMPTY ARRAY
    $RegAddArray = @()
    
    # CHECK IF MORE THAN ONE REGISTRY KEY EXISTS
    if ($Keys.Count -gt 1)
    {
      foreach ($Key in $Keys)
        {
          # OUTPUT KEY TO WRITE-HOST
          Write-Host "Exporting key: $Key"         

          # FIND LOCATION OF $Key IN $Content FILE
          $LoopIndex = $Keys.IndexOf($Key)

          # FIND LOCATION OF NEXT $Key IN $Content FILE
          $nextkey = $Keys[($LoopIndex + 1)]

          # DETERMINE START/END OF $Key CONTENTS
          $StartKeyPath = ($Content.IndexOf($Key) + 1)
          $EndKeyPath= ($Content.IndexOf($nextkey) -1) 
          if ($EndKeyPath -lt 0){$EndKeyPath = $Content.Count}
          
          # EXTRACT REGISTRY KEY VALUES/DATA FROM START/END VALUES IN CONTENT, THEN REMOVE EMPTY LINES  
          $RegValues = $Content[$StartKeyPath .. $EndKeyPath] | ? {$_.Trim() -ne ""}
                     
          # REMOVE BRACKETS FROM KEY
          $RegAdd = $Key.ToString().Replace("[","")
          $RegAdd = $RegAdd.Replace("]","")
         
          # LOOP THROUGH EACH REGISTRY VALUE
          foreach ($RegValue in $RegValues)
            {
              # CHECK IF UNFINISHED STATEMENT
              if ($RegValue -notmatch '^\"')
                { Write-Host "[ERROR] BINARY/QWORD/MULTI_SZ/EXPAND_SZ values are currently not supported." -ForegroundColor Red; Exit }
              # CHECK IF BINARY VALUE
              elseif ($RegValue -match "\=hex\:")
                { Write-Host "[ERROR] BINARY values are currently not supported." -ForegroundColor Red; Exit }
              # CHECK IF QWORD VALUE
              elseif ($RegValue -match "\=hex\(b\)")
                { Write-Host "[ERROR] QWORD values are currently not supported." -ForegroundColor Red; Exit }
              # CHECK IF MULTI STRING VALUE
              elseif ($RegValue -match "\=hex\(7\)")
                { Write-Host "[ERROR] MULTI_SZ values are currently not supported." -ForegroundColor Red; Exit }
              # CHECK IF EXPAND STRING VALUE
              elseif ($RegValue -match "\=hex\(2\)")
                { Write-Host "[ERROR] EXPAND_SZ values are currently not supported." -ForegroundColor Red; Exit }
              # CHECK IF DWORD VALUE
              elseif ($RegValue -match "\=dword\:")
                { 
                  $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
                  $KeyData = $RegValue | %{$_.split('dword:')[-1]}  # SPLIT SECOND QUOTES (DATA VALUE)
                  $KeyData = [System.Convert]::ToInt32($KeyData,16) # CONVERT TO DECIMAL
                  if ($Force -eq $False){ $RegAddArray += 'reg add "' + $RegAdd + '" /t REG_DWORD /v "' + $KeyName + '" /d "' + $KeyData + '"' }
                  if ($Force -eq $True){ $RegAddArray += 'reg add "' + $RegAdd + '" /f /t REG_DWORD /v "' + $KeyName + '" /d "' + $KeyData + '"' }   
                }    
              else 
                { 
                  $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
                  $KeyData = $RegValue | %{$_.split('"')[3]}  # SPLIT SECOND QUOTES (DATA VALUE)
                  if ($Force -eq $False){ $RegAddArray += 'reg add "' + $RegAdd + '" /t REG_SZ /v "' + $KeyName + '" /d "' + $KeyData + '"' }
                  if ($Force -eq $True){ $RegAddArray += 'reg add "' + $RegAdd + '" /f /t REG_SZ /v "' + $KeyName + '" /d "' + $KeyData + '"' }
                }         
            }
        } 
    }

    # CHECK IF ONLY ONE REGISTRY KEY EXISTS
    if ($Keys.Count -eq 1)
    {
      # OUTPUT KEY TO WRITE-HOST
      Write-Host "Exporting key: $Key"         
      
      # DETERMINE START/END OF $Key CONTENTS
      $StartKeyPath = ($Content.IndexOf($Keys) + 1)
      $EndKeyPath = $Content.Count
      
      # EXTRACT REGISTRY KEY VALUES/DATA FROM START/END VALUES IN CONTENT, THEN REMOVE EMPTY LINES
      $RegValues = $Content[$StartKeyPath .. $EndKeyPath] | ? {$_.Trim() -ne ""}
      
      # REMOVE BRACKETS FROM KEY
      $RegAdd = $Keys.ToString().Replace("[","")
      $RegAdd = $RegAdd.Replace("]","")
      
      # LOOP THROUGH EACH REGISTRY VALUE
      foreach ($RegValue in $RegValues)
      {
        # CHECK IF UNFINISHED STATEMENT
        if ($RegValue -notmatch '^\"')
          { Write-Host "[ERROR] BINARY/QWORD/MULTI_SZ/EXPAND_SZ values are currently not supported." -ForegroundColor Red; Exit }
        # CHECK IF BINARY VALUE
        elseif ($RegValue -match "\=hex\:")
          { Write-Host "[ERROR] BINARY values are currently not supported." -ForegroundColor Red; Exit }
        # CHECK IF QWORD VALUE
        elseif ($RegValue -match "\=hex\(b\)")
          { Write-Host "[ERROR] QWORD values are currently not supported." -ForegroundColor Red; Exit }
        # CHECK IF MULTI STRING VALUE
        elseif ($RegValue -match "\=hex\(7\)")
          { Write-Host "[ERROR] MULTI_SZ values are currently not supported." -ForegroundColor Red; Exit }
        # CHECK IF EXPAND STRING VALUE
        elseif ($RegValue -match "\=hex\(2\)")
          { Write-Host "[ERROR] EXPAND_SZ values are currently not supported." -ForegroundColor Red; Exit }
        # CHECK IF DWORD VALUE
        elseif ($RegValue -match "\=dword\:")
          { 
            $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
            $KeyData = $RegValue | %{$_.split('dword:')[-1]}  # SPLIT SECOND QUOTES (DATA VALUE)
            $KeyData = [System.Convert]::ToInt32($KeyData,16) # CONVERT TO DECIMAL
            if ($Force -eq $False){ $RegAddArray += 'reg add "' + $RegAdd + '" /t REG_DWORD /v "' + $KeyName + '" /d "' + $KeyData + '"' }
            if ($Force -eq $True){ $RegAddArray += 'reg add "' + $RegAdd + '" /f /t REG_DWORD /v "' + $KeyName + '" /d "' + $KeyData + '"' }     
          }    
        else 
          { 
            $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
            $KeyData = $RegValue | %{$_.split('"')[3]}  # SPLIT SECOND QUOTES (DATA VALUE)
            if ($Force -eq $False){ $RegAddArray += 'reg add "' + $RegAdd + '" /t REG_SZ /v "' + $KeyName + '" /d "' + $KeyData + '"' }
            if ($Force -eq $True){ $RegAddArray += 'reg add "' + $RegAdd + '" /f /t REG_SZ /v "' + $KeyName + '" /d "' + $KeyData + '"' }
          }         
      }
    }

    # SAVE RESULTS AS .BAT
    $OutPath = $PathObj.FullName.Replace(".reg",".bat")
    $RegAddArray | Out-File $OutPath -Encoding ascii -Force

    # OUTPUT TO HOST IF COMMAND WAS SUCCESSFUL IF RESULTS ARE GREATER THAN 1 LINE (MEDIOCRE ERROR HANDLING I WILL ADMIT)
    If ((Get-Content "$OutPath").Length -gt 1)  
      {Write-Host "[SUCCESS]  Batch file created successfully. Please review file here: $OutPath" -ForegroundColor Green}
    Else {Write-Host "[ERROR] Batch file is empty or was not created. " -ForegroundColor Red; Exit}

}
