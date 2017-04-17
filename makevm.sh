dir=/root/vmtest/
mkdir $dir
VM='UbuntuServer_Blank1'
NIC="eth0"
echo "Building VM Image"
VBoxManage createhd --filename $dir$VM.vdi --size 32768
VBoxManage createvm --name $VM --ostype "Linux_64" --register
VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $dir$VM.vdi
VBoxManage storagectl $VM --name "IDE Controller" --add ide
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium /tmp/ubuntu-16.04-server-amd64-unattended.iso
VBoxManage modifyvm $VM --ioapic on
VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM --memory 512 --vram 12
VBoxManage modifyvm $VM --nic1 bridged --bridgeadapter1 $NIC
VBoxManage modifyvm $VM --vrde on
VBoxManage modifyvm $VM --vrdeport 9000-9500
echo "Running Install process, this may take a few moments depending on your system"
VBoxHeadless -s $VM
echo "Install complete"
#remove the iso image
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium none
