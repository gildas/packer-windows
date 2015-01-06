#

VM=$1

storage_controller='IDE Controller'
storage_port=1
storage_device=0

VBoxManage storageattach $VM --storagectl "$storage_controller" --port $storage_port --device $storage_device --type dvddrive --medium "emptydrive"
