

#read -p 'NAME:' NAME
NAME=test
INIMG=focal-server-cloudimg-amd64.img
IMG=${NAME}.img

echo "*#* Creating meta-data"
cat<<EOF>meta-data
instance-id: $NAME
local-hostname: $NAME
EOF

if [ ! -r ~/.ssh/id_rsa.pub ]
then
	echo "*#* Creating ssh key"
	ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

echo "*#* Creating user-data"
cat<<EOF>user-data
#cloud-config
users:
  - name: root
    chpasswd:
    list: |
    root:root
    lock_passwd: false
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_rsa.pub)
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvp98kR3ee9rK0SdDcTBFwST5gmENlCQ0ALBpmQ5jt8McdzcsW1pJxz4rrA03vkyj+RqkMKhH1XNbrdqj7q/9HEcsDtvz7QSHG5a1tikhzp50Mt6NQ5p28DOgCGwofVlsdFJZp3T/0CIC/V2G5Dif0tWavXBI4CNKwduMB1/oduPK6orYnK2ZUIGQ9hxZ2STSSZEm+a6niy+P4ataiN8qf1c3zWszHalI693CcXq445vt4O33gPOtIBQ8jLPSnTvBgHkvh1TnL/kA2AgQ3nE86FDJoHi5Kbvr12r6i0dTDaCF15gZjlA7n6SozEcrqH5CyEMMaYHZwEhmUM9C6Usnb dimo@dimo-HP-ProBook-6460b
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
EOF

echo "*#* Creating cidata.iso"
genisoimage -output cidata.iso -V cidata -r -J user-data meta-data

echo "*#* Modifying root password for image"
#virt-customize -v -x -a ${INIMG} --root-password password:root
echo "*#* Creating OS image"
qemu-img create -b ${INIMG} -f qcow2 -F qcow2 ${IMG} 10G

echo "*#* Creating VM"
virt-install \
	--name=${NAME} \
	--ram=16384 \
	--vcpus=4 \
	--import \
	--disk path=${IMG},format=qcow2 \
	--disk path=cidata.iso,device=cdrom \
	--os-variant=ubuntu20.04 \
	--network bridge=br-idc,model=virtio \
	--graphics vnc,listen=0.0.0.0 \
	--noautoconsole
