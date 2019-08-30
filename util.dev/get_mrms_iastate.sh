#!/bin/sh
set -x

date1=2019073116
date2=2019082612
NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate

myarch=/gpfs/dell2/ptmp/Ying.Lin/mrms
if [ ! -d $myarch ]; then mkdir -p $myarch; fi
cd $myarch

date=$date1
while [ $date -le $date2 ]
do 
  yyyy=${date:0:4}
    mm=${date:4:2}
    dd=${date:6:2}
  yyyymmdd=${date:0:8}
    hh=${date:8:2}
  urlpfx=http://mtarchive.geol.iastate.edu/$yyyy/$mm/$dd/mrms/ncep
  type1=RadarOnly_QPE_01H
  type2=RadarQualityIndex
  file1=${type1}_00.00_${yyyymmdd}-${hh}0000.grib2.gz
  file2=${type2}_00.00_${yyyymmdd}-${hh}0000.grib2.gz
  wget $urlpfx/$type1/$file1
  wget $urlpfx/$type2/$file2
  date=`$NDATE +1 $date`
done
exit
