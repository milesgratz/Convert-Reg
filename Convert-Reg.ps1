Function Convert-Reg {

<#
.DESCRIPTION
  Script to convert Registry (.reg) files to .bat

.PARAMETERS
  Path (Location of .reg file to convert)

.EXAMPLE
  Convert-Reg -Path "C:\temp\Registry.reg"
    
.AUTHOR
  Miles Gratz (serveradventures.com)	   

.DATE
  03/21/2015
#>

Param (
    [parameter(Mandatory=$True,Position=1)]
      [string]$Path
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
              $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
              $KeyData = $RegValue | %{$_.split('"')[3]}  # SPLIT SECOND QUOTES (DATA VALUE)

              # COMBINE INTO REG ADD STATEMENT
              $RegAddArray += 'reg add "' + $RegAdd + '" /f /v "' + $KeyName + '" /d "' + $KeyData + '"'
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
          $KeyName = $RegValue | %{$_.split('"')[1]}  # SPLIT FIRST QUOTES (VALUE NAME)
          $KeyData = $RegValue | %{$_.split('"')[3]}  # SPLIT SECOND QUOTES (DATA VALUE)

          # COMBINE INTO REG ADD STATEMENT
          $RegAddArray += 'reg add "' + $RegAdd + '" /f /v "' + $KeyName + '" /d "' + $KeyData + '"'
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
