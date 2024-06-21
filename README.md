# fuzzel-iwd

A lightweight and user-friendly Wi-Fi connection manager using `iwctl` and `fuzzel`.

## Description

fuzzel-iwd is a bash script that provides a simple and intuitive interface for managing Wi-Fi connections on systems using iwd.

This project was inspired by [wofi-iwd](https://codeberg.org/bagnaram/menu-iwd)

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
   chmod +x fuzzel-iwd.sh
   ```

2. Run the script:
   ```
   ./fuzzel-iwd.sh
   ```

3. Use the fuzzel menu to select networks, connect, disconnect, or manage saved networks.

## Notes

- Requires root privileges or proper permissions to manage Wi-Fi connections
- Designed for systems using iwd for network management

## Acknowledgments

This project was inspired by [wofi-iwd](https://codeberg.org/bagnaram/menu-iwd) by bagnaram.
