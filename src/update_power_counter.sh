#!/bin/bash
#
# update_power_counter.sh - query the S.M.A.R.T. data and store the state
#
# This fetches the current power count and stores it. It also prints the
# previous power count state and the next expected state. This must be run as
# root or as a user that has access to the specific device.
#

DEVICE="/dev/sda";
STATE_DIR="/var/lib/smartmonster";
PREVIOUS_POWER_COUNT_FILE="$STATE_DIR/previous_power_count";
CURRENT_POWER_COUNT_FILE="$STATE_DIR/current_power_count";
EXPECTED_POWER_COUNT_FILE="$STATE_DIR/expected_power_count";
POWER_INCREMENT=1;

if [ "$USER" != "root" ];
then
  echo "You must be root!";
  exit 1;
fi

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

SMARTCTL="`which smartctl`";
SMARTCTL_ARGS="-A";
POWER_COUNT="Power_Cycle_Count"

CURRENT_POWER_COUNT=`$SMARTCTL $SMARTCTL_ARGS $DEVICE|grep $POWER_COUNT|awk '{print $10}'`;

if [ ! -f "$PREVIOUS_POWER_COUNT_FILE" ];
then
  echo "You have no $PREVIOUS_POWER_COUNT_FILE!";
  echo "Assuming first run and populating with CURRENT_POWER_COUNT";
  echo $CURRENT_POWER_COUNT > $PREVIOUS_POWER_COUNT_FILE;
  echo $PREVIOUS_POWER_COUNT=$CURRENT_POWER_COUNT;
else
  PREVIOUS_POWER_COUNT="`cat $PREVIOUS_POWER_COUNT_FILE`";
  if [ -z $PREVIOUS_POWER_COUNT ];
  then
     PREVIOUS_POWER_COUNT=$CURRENT_POWER_COUNT;
  fi
fi

EXPECTED_NEXT_COUNT="$(expr $CURRENT_POWER_COUNT + $POWER_INCREMENT)";

# Print/export the count data
echo "PREVIOUS_POWER_COUNT=$PREVIOUS_POWER_COUNT";
echo "CURRENT_POWER_COUNT=$CURRENT_POWER_COUNT";
echo "EXPECTED_NEXT_COUNT=$EXPECTED_NEXT_COUNT";
export PREVIOUS_POWER_COUNT=$PREVIOUS_POWER_COUNT;
export CURRENT_POWER_COUNT=$CURRENT_POWER_COUNT;
export EXPECTED_NEXT_COUNT=$EXPECTED_NEXT_COUNT;

# Update the state files
echo $PREVIOUS_POWER_COUNT > $PREVIOUS_POWER_COUNT_FILE;
echo $CURRENT_POWER_COUNT > $CURRENT_POWER_COUNT_FILE;
echo $EXPECTED_NEXT_COUNT > $EXPECTED_POWER_COUNT_FILE;
