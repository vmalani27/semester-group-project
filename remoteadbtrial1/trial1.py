import os
import subprocess
import time

def run_adb_command(command):
    try:
        output = subprocess.check_output(f"adb {command}", shell=True)
        return output.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {e.output.decode('utf-8').strip()}")
        return None

def enable_wireless_adb():
    # Ensure adb server is started
    run_adb_command("start-server")

    # Check if a device is connected via USB
    devices = run_adb_command("devices")
    if "device" not in devices:
        print("No device connected via USB.")
        return
    
    # Restart ADB in TCP/IP mode on port 5555
    run_adb_command("tcpip 5555")
    print("ADB over TCP/IP enabled on port 5555.")
    
    # Wait for the device to switch to TCP/IP mode
    time.sleep(2)
    
    # Get the device IP address
    device_ip = run_adb_command("shell ip -f inet addr show wlan0")
    if device_ip:
        device_ip = device_ip.split("inet ")[1].split("/")[0]
        print(f"Device IP Address: {device_ip}")

        # Connect to the device over Wi-Fi
        run_adb_command(f"connect {device_ip}:5555")
        print(f"Connected to {device_ip}:5555 over Wi-Fi.")
    
    # Disconnect the USB connection (optional)
    run_adb_command("disconnect")
    print("Disconnected USB ADB connection.")

if __name__ == "__main__":
    enable_wireless_adb()