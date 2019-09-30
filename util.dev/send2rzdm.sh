#!/bin/bash
#BSUB -J pcprtma__send2rzdm
#BSUB -P RTMA-T2O
#BSUB -o /ptmpp1/Ying.Lin/cron.out/send2rzdm_rtma.%J
#BSUB -e /ptmpp1/Ying.Lin/cron.out/send2rzdm_rtma.%J
#BSUB -n 1
#BSUB -q "transfer"
#BSUB -W 0:10
#BSUB -R "rusage[mem=300]"
#BSUB -R affinity[core(1)]

set -x

module purge
module load gnu/4.8.5
module load ips/18.0.1.163
module load prod_util/1.1.0

echo 'Actual output starts here:'

RUN=pcprtma

if [ $# -eq 1 ]; then
  date0=$1
else                      
  date0=`date -u +%Y%m%d%H`
fi

day0=`echo $date0 | cut -c 1-8`
hr0=`echo $date0 | cut -c 9-10`

COMOUTrtma=/ptmpp1/emc.rtmapara/Ying.Lin/pcpanl/pcprtma.$day0

RZDMDIR=/home/ftp/emc/mmb/precip/rtma.v2.8.0/pcprtma.$day0
ssh wd22yl@emcrzdm "mkdir -p $RZDMDIR/wmo"
cd $COMOUTrtma
scp pcprtma2.$date0.grb2 pcprtma.$date0.gif rqirtma.$date0.grb2 wd22yl@emcrzdm:$RZDMDIR/.
scp wmo/grib2.t${hr0}z.awprtmapcp.184 wd22yl@emcrzdm:$RZDMDIR/wmo/.

exit

