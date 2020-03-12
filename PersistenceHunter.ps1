<#
.Synopsis
  Queries scheduled task names, executables, and arguments
#>
function Get-PersistenceTasks
{
  Write-Output "[*] Gathering scheduled tasks.."
  Write-Output ""
  Get-ScheduledTask | % { [pscustomobject]@{
    Name = $_.TaskName
    Binary = $_.Actions.Execute
    Arguments = $_.Actions.Arguments
    }
  }
  Write-Output ""
  Write-Output "[*] End of scheduled tasks"
}

<#
.Synopsis
 Queries registry locations associated with Technique 1183 - Image File Execution Options
#>
function Get-IFEO
{
  if (Test-Path -path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\")
  {
    Write-Output "[*] Checking Image Execution File Option keys.."
    Write-Output ""
    
    $IFEOList = Get-ChildItem -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\" |
      where-object { $_.Property -like "*GlobalFlag*" } 
    
    foreach ($k in $keyList) {
        $item = $k | Get-ItemProperty | Where-Object { $_.GlobalFlag -eq 512 } | Select -ExpandProperty PSPath | % {$_.split("::")[2] }
        Write-Output "Match found at $item"
      }
    Write-Output ""
    Write-Output "[*] End of Image File Execution Options check"
  }
  
  else
  {
    Write-Output ""
    Write-Output "[*] HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ not found"
    Write-Output ""
  }
  
  #SilentProcessExit Begin
  if (Test-Path -path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\SilentProcessExit\")
  {
    Write-Output ""
    Write-Output "[*] Checking SilentProcessExit keys.."
    Write-Output ""
    
    $SPEList = Get-ChildItem -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\SilentProcessExit\" |
      where-object { $_.Property -like "*MonitorProcess*" } 
      
    foreach ($k in $SPEList)
    {
      $props = $k | Get-ItemProperty | select @{l="Path";e={$_ | select -expandproperty PSPath | % {$_.split("::")[2] }}}, @{l="BinaryLaunched";e={$_.MonitorProcess }}
      $path = $props.path
      $binary = $props.binaryLaunched
      Write-Output "Match found at $path"
      Write-Output "  Application launched: $binary"
      Write-Output ""
    }
    
    Write-Output "[*] End of SilentProcessExit check"
    Write-Output ""    
  } 
  
  else
  {
    Write-Output ""
    Write-Output "[*] HKLM\Software\Microsoft\Windows NT\CurrentVersion\SilentProcessExit\ not found"
    Write-Output ""
  }
}

function Get-AppShims {
  if (Test-Path -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Custom\")
  {
    Write-Output ""
    Write-Output "[*] Checking App Shim keys.."
    Write-Output ""
    
    $customList = Get-ChildItem -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Custom\"
    
    if (($customList).count -ge 1) {
      foreach ($appMatch in $customList) {
        $customPath = $appMatch.PSPath | Out-String | % { $_.split("::")[2] }
        $guid = $appMatch.Property | Out-String | % { $_.split(".sdb")[0] }
        Write-Output "Match found at $customPath"
        Write-Output "  Checking for associated SDBs.."
        if (Test-Path -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\InstalledSDB\$guid")
        {
          $item = Get-ItemProperty -Path "Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\InstalledSDB\$guid"
          $dbPath = $item.DatabasePath
          Write-Output "    Shim database found at $dbPath - Recommend parsing file"
        }
        Write-Output ""
       }
      }
      Write-Output "[*] End of App Shim Check"
   }
   
   else {
    Write-Output ""
    Write-Output "[*]  HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Custom\ not found"
    Write-Output ""
   }
