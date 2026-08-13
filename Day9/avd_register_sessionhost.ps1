$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$RegistrationToken = $env:REGTOKEN
if (-not $RegistrationToken) {
    throw 'REGTOKEN environment variable is not set.'
}

$dir = 'C:\Temp\AVD'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
Set-Location $dir

$uris = @(
    'https://go.microsoft.com/fwlink/?linkid=2310011',
    'https://go.microsoft.com/fwlink/?linkid=2311028'
)

$installers = @()
foreach ($uri in $uris) {
    $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue).Headers.Location
    if (-not $expandedUri) {
        throw "Could not resolve installer URL: $uri"
    }
    $fileName = Split-Path $expandedUri -Leaf
    Invoke-WebRequest -Uri $expandedUri -OutFile $fileName
    Unblock-File -Path $fileName
    $installers += (Join-Path $dir $fileName)
}

$agentMsi = $installers | Where-Object { $_ -match 'RDAgent\.Installer' }
$bootMsi = $installers | Where-Object { $_ -match 'RDAgentBootLoader\.Installer' }
if (-not $agentMsi) {
    throw 'Agent installer not found after download.'
}
if (-not $bootMsi) {
    throw 'Boot loader installer not found after download.'
}

Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$agentMsi`" REGISTRATIONTOKEN=$RegistrationToken /quiet /qn /norestart" -Wait -NoNewWindow
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$bootMsi`" /quiet /qn /norestart" -Wait -NoNewWindow

Get-Service -Name 'RDAgentBootLoader', 'RDAgent' -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    ConvertTo-Json -Compress

Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Remote Desktop Agent Boot Loader|Remote Desktop Services Infrastructure Agent|Remote Desktop Services Infrastructure Geneva Agent|Remote Desktop Services SxS Network Stack' } |
    Select-Object DisplayName, DisplayVersion |
    ConvertTo-Json -Compress
