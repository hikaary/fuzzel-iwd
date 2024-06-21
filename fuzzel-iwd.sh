#!/usr/bin/env bash

set -e

function fuzzel_menu() {
    fuzzel -d -p "$1"
}

function fuzzel_password() {
    fuzzel -d -p "$1" --password="*"
}

function start_scan() {
    local interface=$(get_interface)
    if ! iwctl station "$interface" scan 2>&1 | grep -q "Operation already in progress"; then
        notify-send "Wi-Fi" "Scanning started"
    else
        notify-send "Wi-Fi" "Scanning already in progress"
    fi
}

function get_networks() {
    local interface=$(get_interface)
    local active_network=$(get_active_network)

    iwctl station "$interface" get-networks \
      | tail -n +5 \
      | head -n -1 \
      | sed -e "s:\[1;30m::g" \
      | sed -e "s:\[0m::g" \
      | sed -e "s:\*\x1b.*:\*:g" \
      | sed -e "s:\x1b::g" \
      | sed -e "s:\[1;90m>::g" \
      | sed -e "s:> *::g" \
      | awk -v active="$active_network" '
    {
          ssid = ""
          for (i = 1; i <= NF - 2; i++) {
              ssid = ssid $i " "
          }
          ssid = substr(ssid, 1, length(ssid) - 1)
          if (length(ssid) > 17) {
              ssid = substr(ssid, 1, 17)
          }

          signal = $NF
          icon = (ssid == active) ? "✅" : "  "

          printf "%s %-17s %s\n", icon, ssid, signal
    }' | sed '/^[[:space:]]*$/d'
}

function get_active_network() {
    iwctl station "$(get_interface)" show | grep "Connected network" | awk '{print $3}'
}

function get_interface() {
    iwctl device list | grep station | awk '{print $2}' | head -n 1
}

function format_networks() {
    local scan_result="$1"
    echo -e "${scan_result}\n🔄 Rescan\n📋 Saved Networks"
}

function connect_or_disconnect() {
    local ssid="$1"
    local active_network="$2"
    local interface=$(get_interface)

    if [[ "$ssid" == "$active_network" ]]; then
        iwctl station "$interface" disconnect
        notify-send "Wi-Fi" "Disconnected from \"$ssid\""
    else
        local is_saved=$(iwctl known-networks list | grep -q "$ssid" && echo "yes" || echo "no")
        
        if [[ "$is_saved" == "yes" ]]; then
            local connection_result=$(iwctl station "$interface" connect "$ssid" 2>&1)
            if [[ $connection_result == *"Operation failed"* ]]; then
                local psk=$(fuzzel_password "🔒 Enter password for $ssid:")
                if [ -n "$psk" ]; then
                    connection_result=$(iwctl --passphrase "$psk" station "$interface" connect "$ssid" 2>&1)
                    if [[ $connection_result != *"Operation failed"* ]]; then
                        iwctl known-networks "$ssid" forget
                        iwctl --passphrase "$psk" known-networks "$ssid" connect
                    else
                        notify-send "Wi-Fi" "Failed to connect to \"$ssid\". Incorrect password."
                        return
                    fi
                else
                    notify-send "Wi-Fi" "Connection cancelled"
                    return
                fi
            fi
        else
            local psk=$(fuzzel_password "🔒 Enter password for $ssid:")
            if [ -n "$psk" ]; then
                connection_result=$(iwctl --passphrase "$psk" station "$interface" connect "$ssid" 2>&1)
                if [[ $connection_result != *"Operation failed"* ]]; then
                    iwctl --passphrase "$psk" known-networks "$ssid" connect
                else
                    notify-send "Wi-Fi" "Failed to connect to \"$ssid\". Incorrect password."
                    return
                fi
            else
                notify-send "Wi-Fi" "Connection cancelled"
                return
            fi
        fi
        
        for i in {1..20}; do
            sleep 0.5
            if [[ "$(get_active_network)" == "$ssid" ]]; then
                notify-send "Wi-Fi" "Connected to \"$ssid\""
                return
            fi
        done
        notify-send "Wi-Fi" "Failed to connect to \"$ssid\""
    fi
}

function get_saved_networks() {
    local active_network=$(get_active_network)
    iwctl known-networks list \
      | tail -n +5 \
      | sed -e "s:\[1;30m::g" \
      | sed -e "s:\[0m::g" \
      | sed -e "s:\*\x1b.*:\*:g" \
      | sed -e "s:\x1b::g" \
      | sed -e "s:\[1;90m>::g" \
      | sed -e "s:> *::g" \
      | awk -v active="$active_network" '
    {
          if (NF >= 5) {
              ssid = $1
              if (length(ssid) > 12) {
                  ssid = substr(ssid, 1, 12)
              }
              security = $2
              last_connected = $3 " " $4 " " $5
              icon = (ssid == active) ? "✅" : "  "
              printf "%s %-12s %-12s %s\n", icon, ssid, security, last_connected
          }
    }' | sed '/^[[:space:]]*$/d'
}

function remove_saved_network() {
    local network="$1"
    iwctl known-networks "$network" forget
    notify-send "Wi-Fi" "Removed saved network \"$network\""
}

function saved_networks_menu() {
    local saved_networks=$(get_saved_networks)
    local selected=$(echo "$saved_networks" | fuzzel_menu "Select network to remove:")
    
    if [ -n "$selected" ]; then
        local network=$(echo "$selected" | awk '{print $2}')
        remove_saved_network "$network"
    fi
}

function main_menu() {
    local scan_result=$(get_networks)
    local active_network=$(get_active_network)
    local formatted_networks=$(format_networks "$scan_result")

    local selected=$(echo -e "$formatted_networks" | fuzzel_menu "Select network:")

    if [[ "$selected" == "🔄 Rescan" ]]; then
        start_scan
        main_menu
        return
    elif [[ "$selected" == "📋 Saved Networks" ]]; then
        saved_networks_menu
        main_menu
        return
    elif [ -z "$selected" ]; then
        return
    fi

    local ssid=$(echo "$selected" | awk '{print $1}')

    if [[ "${selected:0:1}" == "✅" ]]; then
        local ssid=$(echo "$selected" | awk '{print $2}')
        local interface=$(get_interface)
        iwctl station "$interface" disconnect
        notify-send "Wi-Fi" "Disconnected from \"$ssid\""
    else
        connect_or_disconnect "$ssid" "$active_network"
    fi
    main_menu
}

main_menu
