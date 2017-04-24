dir=/ssd/vmtest/
tmp="/tmp"
suffix=$$
vboxversion=$(virtualbox --help | head -n 1 | awk '{print $NF}')
VM='UbuntuServer_'${suffix}_vbox_${vboxversion}
NIC="eth0" #local network interface to bind to
HD=${dir}${VM}.vdi
HD_SIZE=32768 #in megabytes 

guestadditons=VBoxGuestAdditions_${vboxversion}.iso
download_file=http://download.virtualbox.org/virtualbox/${vboxversion}/${guestadditons}

mkdir -p $dir


spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# define download function
# courtesy of http://fitnr.com/showing-file-download-progress-using-wget.html
download()
{
    local url=$1
    local outfile=$2
    echo -n "    "
    wget --progress=dot $url -O $outfile 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    echo -ne "\b\b\b\b"
    echo " DONE"
    echo " Saved to ${outfile}"
}

if [[ ! -f ${tmp}/${guestadditons} ]]; then

    echo -n " downloading ${download_file} "
    download "$download_file" "${tmp}/${guestadditons}"
fi


echo "Building VM Image"
VBoxManage createhd --filename ${HD} --size ${HD_SIZE}
VBoxManage createvm --name $VM --ostype "Linux_64" --register
VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ${HD}
VBoxManage storagectl $VM --name "IDE Controller" --add ide
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium /tmp/ubuntu-16.04.2-server-amd64-unattended.iso
VBoxManage modifyvm $VM --ioapic on
VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM --memory 512 --vram 12
VBoxManage modifyvm $VM --nic1 bridged --bridgeadapter1 ${NIC}
VBoxManage modifyvm $VM --vrde on
VBoxManage modifyvm $VM --vrdeport 9000-9500
echo "Running Install process, this may take a few moments depending on your system"

(VBoxHeadless -s $VM ) &
spinner $!
echo "Install complete"
#remove the iso image , remove the install cd and attach the guest additons , so we can finish install
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium none
echo "Attaching guest tools iso"
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ${tmp}/${guestadditons}
echo "Starting vm and performing guest additions install"
(VBoxHeadless -s $VM ) &
spinner $!
echo "Build Complete"