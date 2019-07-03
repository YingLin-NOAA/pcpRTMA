#!/bin/bash
#BSUB -J pcprtma__send2rzdm
#BSUB -P RTMA-T2O
#BSUB -o /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_rtma.%J
#BSUB -e /gpfs/dell2/ptmp/Ying.Lin/cron.out/send2rzdm_rtma.%J
#BSUB -n 1
#BSUB -q "dev_transfer"
#BSUB -W 0:10
#BSUB -R "rusage[mem=300]"
#BSUB -R affinity[core(1)]

set -x

module purge
module load gnu/4.8.5
module load ips/18.0.1.163
module load prod_util/1.1.0

RUN=pcprtma

if [ $# -eq 1 ]; then
  date0=$1
else                      
  now=`date -u +%Y%m%d%H`
  date0=`$NDATE -1 $now`
fi

day0=`echo $date0 | cut -c 1-8`

COMOUTrtma=/gpfs/dell2/ptmp/Ying.Lin/pcpanl/pcprtma.$day0

RZDMDIR=/home/ftp/emc/mmb/precip/rtma.v2.8.0/pcprtma.$day0
ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR"
cd $COMOUTrtma
scp  pcprtma2.$date0.* wd22yl@emcrzdm:$RZDMDIR/.

exit

