VBoxManage controlvm "k8s-master-1" poweroff soft
VBoxManage controlvm "k8s-node-1" poweroff soft
VBoxManage controlvm "k8s-node-2" poweroff soft
VBoxManage controlvm k8s-api-lb1 poweroff soft
#VBoxManage controlvm "k8s-node-3"  poweroff soft