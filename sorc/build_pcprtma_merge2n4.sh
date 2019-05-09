set -x

##############################

BASE=`pwd`
export BASE

. /usrx/local/Modules/default/init/ksh
module purge
module use -a ${BASE}/../modulefile
module load RTMA/v2.7.0

module list

cd ${BASE}/pcprtma_merge2n4.fd
make clean
make
make mvexec
make clean

##############################
