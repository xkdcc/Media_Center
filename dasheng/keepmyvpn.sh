#!/bin/bash

#******************************************************************************
# Information:
# 1. transmission-daemon service
#    If running, systemctl status return 0
#    If inactive (dead), systemctl status return 3
#    If start success, systemctl status return 0
#    If start fail, systemctl status return 1
#    If stop success, systemctl status return 0
#    If stop fail, systemctl status return non-zero


#******************************************************************************
# Global Settings.
SCRIPTS_DIR=/home/piba/brant/programs/bin
. ${SCRIPTS_DIR}/bclog.sh
log_msg "SCRIPTS_DIR: $SCRIPTS_DIR"

myip_sh=/home/piba/brant/programs/bin/myip.sh
f_stopped_td=0 # Flag to save whether this script stopped transmission-daemon.

#******************************************************************************
# functions
#

#******************************************************************************
# Wrapper for systemctl_operation()
# Please note: the return value can not return value out of range [0, 255]
#
systemctl_operation_core() {
  trace_in
  action=$1 # start/status/stop
  sname=$2
  display_format=$3 # If 1, will print prefix line and suffix line
  [[ -n $display_format ]] || display_format=1

  if [ $display_format -eq 1 ]; then
    log_line
  fi

  sudo systemctl $1 $2 >> $log_file 2>&1
  ret=$?

  if [ $display_format -eq 1 ]; then
    log_line
  fi
  log_msg "Actual return value from systemctl_operation_core: $ret"
  trace_out
  return $ret
}

#******************************************************************************
# Wrapper of systemctl_operation_core().
# If $loop_count=0, run the systemctl operation till a 0 exit value which means success.
# TODO:
# 1. Should not use infinite loop but adding notification mechanism at certain condition.
#
systemctl_operation() {
  action=$1 # start/status/stop
  sname=$2
  display_format=$3 # If 1, will print prefix line and suffix line
  [[ -n $display_format ]] || display_format=1
  expect_exit_value=$4   # -1 means ignore the exit value, this is useful for just showing status  
  # If $5 is 0, means infinite loop till a success
  # Default is 1
  loop_count=$5 # If $expect_exit_value is -1, will set $loop_count to 1 by default
  [[ -n $loop_count ]] && [[ expect_exit_value -ne -1 ]] || loop_count=1
  count=0

  while [ 1 ]; do
    count=$(($count+1))
    log_msg "[systemctl:$count] Trying to call systemctl to $action $sname..."
    systemd-notify --ready --status="[systemctl:$count] Trying to call systemctl to $action $sname..."
    systemctl_operation_core $action $sname $display_format
    ret=$?
    if [ $expect_exit_value -ne -1 ]; then
      # If meet $expect_exit_value, return
      if [ $ret -eq $expect_exit_value ]; then
        log_msg "Expect value[$expect_exit_value] match actual exit value[$ret] for systemctl $action $sname."
        break
      else
        log_msg "Actual exit value[$ret] failed to meet expect value[$expect_exit_value] for systemctl $action $sname."
      fi
    fi
    # If not meet, checking whether need to continue to try
    if [ $loop_count -eq 0 ] || [ $loop_count -lt $count ]; then        # Infinite loop
      log_msg "[systemctl:$count][loop_count:$loop_count][count:$count] Sleep 5s to rety calling systemctl to $action $sname..."
      systemd-notify --ready --status="[systemctl:$count][loop_count:$loop_count][count:$count] Sleep 5s to rety calling systemctl to $action $sname..."
      sleep 5
      continue
    elif [ $loop_count -eq $count ]; then
      log_msg "[systemctl:$count][loop_count:$loop_count][count:$count] Sleep 5s then exit systemctl_operation at systemctl $action $sname..."
      systemd-notify --ready --status="[systemctl:$count][loop_count:$loop_count][count:$count] Sleep 5s then exit systemctl_operation at systemctl $action $sname..."
      sleep 5
      break
    fi
  done

  return $ret
}

#******************************************************************************
# Start vpn.
#
start_vpn() {
  log_msg "Starting VPN..." 1
  $myip_sh -s >> $log_file 2>&1
  log_line
  log_msg "Checking whether VPN is started successfully..."
  $myip_sh | grep -E -q "^tun0.*tun\s+tun0\s*$"
  vpn_err=$?
  if [ $vpn_err -ne 0 ]; then
    log_msg "Failed to start VPN."
  else
    log_msg "VPN has been started successfully."
  fi
  return $vpn_err
}

#******************************************************************************
# Show vpn.
#
#show_vpn_status() {
#}
cycle_count=0
while [ 1 ]; do
  cycle_count=$(($cycle_count+1))
  log_msg ""
  log_msg "Showing VPN status..." 1
  $myip_sh >> $log_file 2>&1
  log_line

  log_msg "Checking whether VPN is enabled..."
  $myip_sh | grep -E -q "^tun0.*tun\s+tun0\s*$"
  vpn_err=$?
  if [ $vpn_err -ne 0 ]; then
    
    log_msg "Looks like VPN is not enabled."

    # Need to stop transmission if is running
    log_msg "Checking whether transmission-daemon is running..." 1
    # Show cutoff-line, tell systemctl_operation() to ignore check return value but just return it, check once
    systemctl_operation status transmission-daemon 1 -1 1
    ret=$?
    if [ $ret -ne 3 ]; then
      log_msg "transmission-daemon is running and will be terminated."
      # expect value 0, infinite loop
      # Not show cutoff-line, not to ignore the return value, check infinitely
      f_stopped_td=1
      log_msg "[f_stopped_td:$f_stopped_td]Stopping transmission-daemon..."
      systemctl_operation stop transmission-daemon 0 0 0
      log_msg "Showing transmission-daemon status..."
      systemctl_operation status transmission-daemon 1 -1 1
    else
      log_msg "transmission-daemon is stopped."
    fi

    # Start VPN
    vpn_count=0
    while [ $vpn_err -ne 0 ]; do
      vpn_count=$(($vpn_count+1))
      start_vpn
      vpn_err=$?
      if [ $vpn_err -eq 0 ]; then
        log_msg "[$cycle_count][VPN:$vpn_count] Sleep 5s. VPN is fixed in this monitor cycle."
        systemd-notify --ready --status="[$cycle_count][VPN:$vpn_count] Sleep 5s. VPN is fixed in this monitor cycle."
        sleep 5
      else
        log_msg "[$cycle_count][VPN:$vpn_count] Sleep 5s to re-try starting VPN in this monitor cycle..."
        systemd-notify --ready --status="[$cycle_count][VPN:$vpn_count] Sleep 5s to re-try starting VPN in this monitor cycle..."
        sleep 5
      fi
    done
  else
    log_msg "VPN is enabled."
    # We should not print below msg "No action taken" if $f_stopped_td is 1.
    if [ $f_stopped_td -eq 0 ]; then
      log_msg "[$cycle_count] This cycle is done. No action taken. VPN is enabled in this monitor cycle. Sleep 30s to start next monitor cycle."
      systemd-notify --ready --status="[$cycle_count] This cycle is done. No action taken. VPN is enabled in this monitor cycle. Sleep 30s to start next monitor cycle."
    fi
  fi

  if [ $f_stopped_td -eq 1 ]; then
    log_msg "[$cycle_count] We have stopped transmission-daemon, now VPN is good, need to re-start transmission-daemon in this cycle..."
    systemd-notify --ready --status="[$cycle_count] Trying to re-start transmission-daemon once after VPN is good..."

    # Try once to start, expect value 0
    systemctl_operation start transmission-daemon 0 0 1
    # Show status
    systemctl_operation status transmission-daemon 1 0 1
    ret=$?
    if [ $ret -eq 0 ];then
      log_msg "[$cycle_count] This cycle is done. transmission-daemon is re-started. Sleep 30s to start next cycle."
      f_stopped_td=0
      systemd-notify --ready --status="[$cycle_count] This cycle is done. transmission-daemon is re-started. Sleep 30s to start next cycle."
    else
      log_msg "[$cycle_count] This cycle is done. Failed to start transmission-daemon. Sleep 30s to start next cycle."
      systemd-notify --ready --status="[$cycle_count] This cycle is done. Failed to start transmission-daemon. Sleep 30s to start next cycle."
    fi
  fi

  sleep 30
done
