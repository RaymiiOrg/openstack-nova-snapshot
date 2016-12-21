#!/bin/bash
# License: GNU GPLv3
# Author: Remy van Elst, https://raymii.org
# Script to create snapshot of Nova Instance (to glance)
# Place the computerc file in: /root/.openstack_snapshotrc

# To restore to a new server:
# nova boot --image "SNAPSHOT_NAME" --poll --flavor "Standard 1" --availability-zone NL1 --nic net-id=00000000-0000-0000-0000-000000000000 --key "SSH_KEY" "VM_NAME"
# To restore to this server (keep public IP)
# nova rebuild --poll "THIS_INSTANCE_UUID" "SNAPSHOT_IMAGE_UUID"

# OpenStack Command Line tools required:
# apt-get install python-novaclient
# apt-get install python-keystoneclient
# apt-get install python-glanceclient

# Or for older/other distributions:
# apt-get install python-pip || yum install python-pip
# pip install python-novaclient
# pip install python-keystoneclient
# pip install python-glanceclient

# To create a snapshot before an apt-get upgrade:
# Place the following in /etc/apt/apt.conf.d/00glancesnapshot
# DPKG::Pre-Invoke {"/bin/bash /usr/local/bin/glance-image-create.sh";};

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

# First we check if all the commands we need are installed.
command_exists() {
  command -v "$1" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "I require $1 but it's not installed. Aborting."
    exit 1
  fi
}

for COMMAND in "nova" "glance" "dmidecode" "tr"; do
  command_exists "${COMMAND}"
done

# Check if the computerc file exists. If so, assume it has the credentials.
if [[ ! -f "/root/.openstack_snapshotrc" ]]; then
  echo "/root/.openstack_snapshotrc file required."
  exit 1
else
  source "/root/.openstack_snapshotrc"
fi

# backup_type
BACKUP_TYPE="${1}"

if [[ -z "${BACKUP_TYPE}" ]]; then
  BACKUP_TYPE="manual"
fi

# rotation of snapshots
ROTATION="${2}"

if [[ -z "${ROTATION}" ]]; then
  ROTATION="7"
fi

# The nova UUID is accessible via dmidecode, but it's all caps.
THIS_INSTSANCE_UUID="$(dmidecode --string system-uuid | tr '[:upper:]' '[:lower:]')"

# snapshot names will sort by date, hostname and UUID.
SNAPSHOT_NAME="backup-snapshot-$(date "+%Y%m%d-%H:%M")-$(hostname)-${THIS_INSTSANCE_UUID}"

echo "INFO: Start OpenStack snapshot creation."

nova backup "${THIS_INSTSANCE_UUID}" "${SNAPSHOT_NAME}" "${BACKUP_TYPE}" "${ROTATION}"
if [[ "$?" != 0 ]]; then
  echo "ERROR: nova image-create \"${THIS_INSTSANCE_UUID}\" \"${SNAPSHOT_NAME}\" \"${BACKUP_TYPE}\" \"${ROTATION}\" failed."
  exit 1
else
  echo "SUCCESS: Backup image created and pending upload."
fi
