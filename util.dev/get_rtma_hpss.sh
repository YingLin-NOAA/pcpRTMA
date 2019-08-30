#!/bin/sh
set -x

#day=$1
day1=20190731
day2=20190731

# theia:
# finddate=/scratch4/NCEPDEV/rstprod/nwprod/util/ush/finddate.sh

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day1

wrkdir=/gpfs/dell2/emc/verification/noscrub/Ying.Lin/prod_rtma_save

while [ $day -le $day2 ];
do 
  mkdir -p $wrkdir/pcprtma.$day
  cd $wrkdir/pcprtma.$day
  yyyy=`echo $day | cut -c 1-4`
  yyyymm=`echo $day | cut -c 1-6`
  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/com2_rtma_prod_pcprtma.$day.tar
  day=`$FINDDATE $day d+1`
done

exit
