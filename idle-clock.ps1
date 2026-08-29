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

$idleLimit = 30   # ثانية قبل ظهور الساعة (عدّلها كما تريد)
$page = "file:///C:/Users/DELL/Desktop/pictures/website/prayer-clock.html"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

while ($true) {
  Start-Sleep -Seconds 4
  try {
    $idle = Get-IdleSeconds
    # هل نافذة الساعة مفتوحة؟ (نبحث عن عمليات Edge تحمل رابط الصفحة)
    $clock = Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*prayer-clock*" }
    $isOpen = $clock.Count -gt 0
    if (-not $isOpen -and $idle -ge $idleLimit) {
      Start-Process $edge -ArgumentList "--start-fullscreen", $page | Out-Null
    }
    elseif ($isOpen -and $idle -lt 5) {
      foreach ($p in $clock) {
        & taskkill.exe /PID $p.ProcessId /T /F | Out-Null
      }
    }
  } catch { }
}
