# Wi-Fi Connection Script

A bash script for managing Wi-Fi connections using `iwctl` and `fuzzel`.

## Features

- Scan for available networks
- Connect to Wi-Fi networks
- Disconnect from current network
- View and manage saved networks
- User-friendly interface using `fuzzel`

## Requirements

- `iwctl` (iwd)
- `fuzzel`
- `notify-send`

## Usage

1. Make the script executable:
   ```
   chmod +x wifi.sh
   ```

2. Run the script:
   ```
   ./wifi.sh
   ```

3. Use the fuzzel menu to select networks, connect, disconnect, or manage saved networks.

## Notes

- Requires root privileges or proper permissions to manage Wi-Fi connections
- Tested on systems using iwd for network management
