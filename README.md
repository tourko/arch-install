Build ARCH ISO image.

First time build a repo:
# sh build_repo.sh

Build the image:
# sh build.sh

Before new build:
# clean.sh

Image is located in out/

To test in VM:
# sudo virsh net-define network.xml
# sudo virsh net-start default
# sh ./run_vm.sh

*** Installation ***

It installs on the first SCSI drive.
!!! All data on that drive are wiped out before the installation !!!
'root' is disabled.
Default admin user 'at'. No password.
