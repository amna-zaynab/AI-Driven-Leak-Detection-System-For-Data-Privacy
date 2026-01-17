#!/bin/bash
# ADB Port Forward Setup Script
# This script sets up port forwarding so that the device can access the Django server

echo "Setting up ADB port forward..."
adb devices

# Forward port 8000 from device to host
adb forward tcp:8000 tcp:8000

echo "Port forward setup complete!"
echo "Now the device can access the Django server at http://localhost:8000/"
