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
public class F {
  [DllImport("user32.dll")]
  public static extern bool SetForegroundWindow(IntPtr h);
}
"@

function Get-IdleSeconds {
  $li = New-Object Idle+LASTINPUTINFO
  $li.cbSize = [uint32]([System.Runtime.InteropServices.Marshal]::SizeOf($li))
  [Idle]::GetLastInputInfo([ref]$li) | Out-Null
  return ([Idle]::GetTickCount() - $li.dwTime) / 1000.0
}

$idleLimit = 30   # ثانية قبل ظهور الساعة (عدّلها كما تريد)
$page = "file:///C:/Users/DELL/Desktop/pictures/website/prayer-clock.html"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

while ($true) {
  Start-Sleep -Seconds 4
  try {
    $idle = Get-IdleSeconds
    $clock = Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*prayer-clock*" }
    $isOpen = $clock.Count -gt 0
    if (-not $isOpen -and $idle -ge $idleLimit) {
      $si = New-Object System.Diagnostics.ProcessStartInfo("cmd.exe")
      $si.Arguments = '/c start "" "' + $edge + '" --start-fullscreen "' + $page + '"'
      $si.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
      [System.Diagnostics.Process]::Start($si) | Out-Null
    }
    elseif ($isOpen -and $idle -lt 5) {
      foreach ($c in $clock) {
        & taskkill.exe /PID $c.ProcessId /T /F | Out-Null
      }
    }
  } catch { }
}
