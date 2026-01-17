# ADB Port Forward Setup Script for PowerShell
# This script sets up port forwarding so that the device can access the Django server

Write-Host "Setting up ADB port forward..." -ForegroundColor Green
adb devices

# Forward port 8000 from device to host
Write-Host "`nForwarding port 8000..." -ForegroundColor Yellow
adb forward tcp:8000 tcp:8000

Write-Host "`n✅ Port forward setup complete!" -ForegroundColor Green
Write-Host "Now the device can access the Django server at http://localhost:8000/" -ForegroundColor Cyan
Write-Host "`nConnected devices:" -ForegroundColor Green
adb devices
