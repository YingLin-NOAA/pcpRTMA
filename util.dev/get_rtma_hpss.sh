#!/bin/sh
set -x

day1=20190828
day2=20190930

# theia:
# finddate=/scratch4/NCEPDEV/rstprod/nwprod/util/ush/finddate.sh

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day2

datadir=/gpfs/dell2/ptmp/Ying.Lin/prod_rtma

while [ $day -ge $day1 ];
do 
  mkdir -p $datadir/pcprtma.$day
  cd $datadir/pcprtma.$day
  yyyy=`echo $day | cut -c 1-4`
  yyyymm=`echo $day | cut -c 1-6`
#  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/com2_rtma_prod_pcprtma.$day.tar
  htar xvf /NCEPPROD/hpssprod/runhistory/rh${yyyy}/$yyyymm/$day/gpfs_dell2_nco_ops_com_rtma_prod_pcprtma.$day.tar
  day=`$FINDDATE $day d-1`
done

exit
