#!/bin/sh

#******************************************************************************
# Warning: Need to put your VPN profile name in startvpn!
#******************************************************************************

G_Flag_help=0
G_Flag_view=0
G_Flag_startvpn=0
ECHO="/bin/echo -e"

#******************************************************************************
# Judge user's input
#

parse_parameters ()
{
  #myip.sh [-s] [-v] [-h]
  while getopts :shv: name
  do
    case $name in
      h) usage
         exit 0;;
      v) G_Flag_view=1;;
      s) G_Flag_startvpn=2;;
      \?) ${ECHO} ""
         ${ECHO} "[ERR] Invalid options: $OPTARG"
         usage
         exit 2;;
    esac
  done
}

#******************************************************************************
# Print help.
#

usage ()
{
  $ECHO "
Usage:
myip.sh [-h] [-v] [-s]
Example:
  1.myip.sh -h
    Show usage.
  2.myip.sh -v
    Show current ip information.
  3.myip.sh -s
    Start VPN.
  "
}

#******************************************************************************
# show_cur_ip
#
show_cur_ip() {
  nmcli con
  echo
  cur_ip=`curl -s -4 icanhazip.com`
  echo "Current IP: $cur_ip"
  curl -s https://ipapi.co/$cur_ip/json/ |grep -E "(city|region)"
}

#******************************************************************************
# startvpn
#
startvpn() {
  sudo nmcli con up id <vpn profile name>
  show_cur_ip
}

#******************************************************************************
# main
#

main ()
{
  parse_parameters "$@"

  # Get user options
  user_option_result=`echo $(( ${G_Flag_help} | ${G_Flag_view} | ${G_Flag_startvpn} ))`

  if [ ${user_option_result} -eq 1 ]; then
    show_cur_ip
  elif [ ${user_option_result} -eq 2 ]; then
    startvpn
  else
    show_cur_ip
  fi
}

################################### MAIN ######################################

main $@
