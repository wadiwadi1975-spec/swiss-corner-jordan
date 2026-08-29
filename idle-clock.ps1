Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Idle {
  [StructLayout(LayoutKind.Sequential)]
  public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
  [DllImport("user32.dll")]
  public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
  [DllImport("kernel32.dll")]
  public static extern uint GetTickCount();
}
"@

function Get-IdleSeconds {
  $li = New-Object Idle+LASTINPUTINFO
  $li.cbSize = [uint32]([System.Runtime.InteropServices.Marshal]::SizeOf($li))
  [Idle]::GetLastInputInfo([ref]$li) | Out-Null
  return ([Idle]::GetTickCount() - $li.dwTime) / 1000.0
}

$idleLimit = 120   # ثانيتان قبل ظهور الساعة (عدّلها كما تريد)
$page = "file:///C:/Users/DELL/Desktop/pictures/website/prayer-clock.html"
$runningPid = $null

while ($true) {
  Start-Sleep -Seconds 4
  $idle = Get-IdleSeconds
  if ($null -eq $runningPid -and $idle -ge $idleLimit) {
    $p = Start-Process "msedge.exe" -ArgumentList "--start-fullscreen", $page -PassThru
    $runningPid = $p.Id
  }
  elseif ($null -ne $runningPid -and $idle -lt 5) {
    & taskkill.exe /PID $runningPid /T /F | Out-Null
    $runningPid = $null
  }
}
