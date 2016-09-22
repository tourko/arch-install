iBuild ARCH ISO image.

First time build a repo:
# archlive/airootfs/opt/install/repo.sh --build

Build the image:
# sh build.sh

Clean up repo:
# archlive/airootfs/opt/install/repo.sh --clean

Clean build artifacts:
# clean.sh

Image is located in archlive/out/

To test in VM:
# sudo virsh net-define network.xml
# sudo virsh net-start default
# sh ./run_vm.sh

*** Installation ***

It installs on the first SCSI drive.
!!! All data on that drive are wiped out before the installation !!!
'root' with no password.
