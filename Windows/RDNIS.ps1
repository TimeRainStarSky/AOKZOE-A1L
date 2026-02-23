# 1. 检查并请求管理员权限
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -ErrorAction Stop
    exit
}

# 2. 定义 RNDIS 网卡所在的注册表根路径
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"

# 3. 获取该路径下所有的子项 (0000, 0001 等)
$subKeys = Get-ChildItem -Path $registryPath -ErrorAction SilentlyContinue

$found = $false
foreach ($key in $subKeys) {
    # 检查驱动描述是否包含 "Remote NDIS"
    $driverDesc = Get-ItemProperty -Path $key.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue
    if ($driverDesc -and $driverDesc.DriverDesc -like "*Remote NDIS*") {
        Write-Host "找到 RNDIS 设备: $($driverDesc.DriverDesc) 在项 $($key.PSChildName)" -ForegroundColor Cyan
        # 4. 添加或修改 *NdisDeviceType 为 1
        # Force 参数确保如果已存在则覆盖
        New-ItemProperty -Path $key.PSPath -Name "*NdisDeviceType" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Host "成功设置 *NdisDeviceType = 1" -ForegroundColor Green
        $found = $true
    }
}

if ($found) {
    Write-Host "`n操作完成！请重新插拔 USB 或在设备管理器中禁用再启用网卡生效。" -ForegroundColor White -BackgroundColor Blue
} else {
    Write-Host "未发现 RNDIS 网卡，请确保手机已连接并开启了 USB 共享网络。" -ForegroundColor Yellow
}
pause