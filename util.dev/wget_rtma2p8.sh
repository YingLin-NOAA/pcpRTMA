#!/bin/sh
set -x

day1=20190828
day2=20190930

UTILROOT=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2
FINDDATE=$UTILROOT/ush/finddate.sh

day=$day1

datadir=/gpfs/dell2/ptmp/Ying.Lin/wget_rtma2p8

while [ $day -le $day2 ];
do 
  mkdir -p $datadir/pcprtma.$day
  cd $datadir/pcprtma.$day
  URLPATH=https://ftp.emc.ncep.noaa.gov/mmb/precip/rtma.v2.8.0/pcprtma.$day/
  wget ${URLPATH}/pcprtma2.${day}{00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23}.grb2

  day=`$FINDDATE $day d+1`
done

exit
