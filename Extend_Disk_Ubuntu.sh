#!/bin/bash
# Auto extend LVM on Ubuntu VM
# Author: BacPV

DISK="/dev/sda"
VG_NAME="ubuntu-vg"
LV_NAME="ubuntu-lv"

# Tìm partition số tiếp theo
NEXT_PART=$(lsblk -nr $DISK | tail -n 1 | awk '{print $1}' | sed 's/sda//')
if [[ -z "$NEXT_PART" ]]; then
  PART_NUM=4
else
  PART_NUM=$((NEXT_PART+1))
fi

NEW_PART="${DISK}${PART_NUM}"

echo "[INFO] Creating new partition $NEW_PART ..."

# Tạo partition mới với fdisk (primary, type 8e Linux LVM)
(
echo n    # new partition
echo      # default (primary)
echo $PART_NUM
echo      # default - first sector
echo      # default - last sector (use all space)
echo t    # change type
echo $PART_NUM
echo 8e   # Linux LVM
echo w    # write changes
) | fdisk $DISK

# Reload partition table
partprobe $DISK

# Tạo physical volume
pvcreate $NEW_PART

# Extend PV (optional)
pvresize $NEW_PART

# Extend VG
vgextend $VG_NAME $NEW_PART

# Extend LV (full free space)
lvextend -l +100%FREE /dev/$VG_NAME/$LV_NAME

# Resize filesystem
resize2fs /dev/$VG_NAME/$LV_NAME

# Show result
df -h | grep $LV_NAME
