#!/bin/bash
#
# smartmonster_sleep.d.sh - hook sleep, hibernate and shutdown events
#
#

if [ "$USER" != "root" ];
then
  echo "You must be root!";
  exit 1;
fi

STATE_DIR="/var/lib/smartmonster";
HOOK_DIR="/etc/pm/sleep.d/";
HIBERNATE_DATE_STAMP="$STATE_DIR/hibernate.stamp";
SUSPEND_DATE_STAMP="$STATE_DIR/suspend.stamp";
THAW_DATE_STAMP="$STATE_DIR/thaw.stamp";
RESUME_DATE_STAMP="$STATE_DIR/resume.stamp";
UNHANDLED_STAMP="$STATE_DIR/unhandled.stamp";

# XXX: Hello TOCTOU!
if [ ! -d "$STATE_DIR" ];
then
  echo "You have no $STATE_DIR; creating it!";
  mkdir -p $STATE_DIR;

  if [ $? != 0 ];
  then
    echo "Unable to create $STATE_DIR!";
    exit 1;
  fi

fi

# Load the common power related functions
. /usr/lib/pm-utils/functions

case "$1" in
  hibernate)
    update_power_counter.sh;
    date -R > $HIBERNATE_DATE_STAMP;
    ;;
  suspend)
    update_power_counter.sh;
    date -R > $SUSPEND_DATE_STAMP;
    ;;
  thaw)
    date -R > $THAW_DATE_STAMP;
    ;;
  resume)
    update_power_counter.sh;
    date -R > $RESUME_DATE_STAMP;
    ;;

    *)
    echo "Unhandled case: $1" > $UNHANDLED_STAMP;
    ;;
esac

exit $?
