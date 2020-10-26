#!/bin/bash

TS=`/bin/date +%m%d%y%H%M%S`
program_name=$(basename $0)
# Make sure the account running this script has the permission to write into /var/log/
log_file=/var/log/${program_name}_$TS.log
alias trace_in='log_msg  "--> ENTERING <$FUNCNAME>" 0'
alias trace_out='log_msg "<-- LEAVING  <$FUNCNAME>" 0'

log_line() {
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file
}

log_msg() {
  local message=$1
  echo -E "[$(date +'%F %T')] $message" >> $log_file
}
