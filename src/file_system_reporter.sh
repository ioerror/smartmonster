#!/bin/bash
#
# file_system_reporter.sh - hash the files on the boot device and compare
#
# This hashes files in $BOOTDEVICE_FILESYSTEM recursively and hashes the entire
# $BOOTDEVICE as well This must be run as root or as a user that has access to
# the specific device.
#

BOOTDEVICE="/dev/sda1";
BOOTDEVICE_FILESYSTEM="/boot/";
STATE_DIR="/var/lib/smartmonster";
PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE="$STATE_DIR/previous_bootdevice_files_state";
CURRENT_BOOTDEVICE_FILESYSTEM_FILE="$STATE_DIR/current_bootdevice_files_state";
PREVIOUS_BOOTDEVICE_RAW_FILE="$STATE_DIR/previous_bootdevice_raw_state";
CURRENT_BOOTDEVICE_RAW_FILE="$STATE_DIR/current_bootdevice_raw_state";
TAMPER=0;
HASHER="`which sha256deep`";
HASHER_ARGS="-r";

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

# Hash all files and store the state in $STATE_DIR
echo "Hashing files in $BOOTDEVICE_FILESYSTEM";
if [ ! -f "$PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE" ];
then
  echo "You have no $PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE!";
  echo "Assuming first run and populating with hashes!";
  $HASHER $HASHER_ARGS $BOOTDEVICE_FILESYSTEM > $PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE;
  cp -f $PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE $CURRENT_BOOTDEVICE_FILESYSTEM_FILE;
else
  $HASHER $HASHER_ARGS $BOOTDEVICE_FILESYSTEM > $CURRENT_BOOTDEVICE_FILESYSTEM_FILE;
fi

# Diff and recurse
HASHER_ARGS="-r -x";
# Now attempt to detect a miss-match of hashes in the $BOOTDEVICE_FILE path
$HASHER $HASHER_ARGS $PREVIOUS_BOOTDEVICE_FILESYSTEM_FILE $BOOTDEVICE_FILESYSTEM;
HASHER_RESULT=$?;
if [ "$HASHER_RESULT" -ge 2 ];
then
  echo "Files on $BOOTDEVICE_FILESYSTEM appear to be mismatched - tampering detected?";
  TAMPER=1;
fi

# Hash $BOOTDEVICE and store the state in $STATE_DIR
echo "Hashing $BOOTDEVICE";
if [ ! -f "$PREVIOUS_BOOTDEVICE_RAW_FILE" ];
then
  echo "You have no $PREVIOUS_BOOTDEVICE_RAW_FILE!";
  echo "Assuming first run and populating with hashes!";
  $HASHER $BOOTDEVICE > $PREVIOUS_BOOTDEVICE_RAW_FILE;
else
  $HASHER $BOOTDEVICE > $CURRENT_BOOTDEVICE_RAW_FILE;
fi

# Diff
HASHER_ARGS="-x";
# Now attempt to detect a miss-match with the $BOOTDEVICE itself
$HASHER $HASHER_ARGS $PREVIOUS_BOOTDEVICE_RAW_FILE $BOOTDEVICE;
HASHER_RESULT=$?;
if [ "$HASHER_RESULT" -ge 3 ];
then
  echo "Files on $BOOTDEVICE_FILESYSTEM appear to be mismatched - tampering detected?";
  TAMPER=1;
fi

if [ "$TAMPER" -eq 1 ];
then
  echo "Possible tampering detected - please inspect with caution!";
  exit 1;
else
  exit 0;
fi
