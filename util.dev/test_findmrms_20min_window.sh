#!/bin/sh
set -x
# test script: for a given yyyymmddhh, list all RadarOnly_QPE_01H files that
# are within +/- 10 minutes of hh:00
#
NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate
MRMSDIR=/gpfs/tp1/nco/ops/dcom/us007003/ldmdata/obs/upperair/mrms/conus/RadarOnly_QPE
date=$1
day=${date:0:8}
hr=${date:8:2}
datem1h=`$NDATE -1 $date`
daym1h=${datem1h:0:8}
hrm1=${datem1h:8:2}

rm -f file.list

file=RadarOnly_QPE_01H_00.00_${day}-${hr}0000.grib2.gz
if [ -s $MRMSDIR/$file ]
then
  echo $file > file.list
fi

deltamin=1
while [ $deltamin -le 10 ];
do
  let minuteplus=$deltamin      # 01, 02, 03, ..., 10  
  let minuteminus=60-$deltamin  # 59, 58, 57, ..., 50

  # fill in leading zeros (so it'll be 01, 02, rather than 1, 2,...'
  minuteplus_2=`printf "%0*d\n" 2 $minuteplus`
  minuteminus_2=`printf "%0*d\n" 2 $minuteminus`
 
  for datestamp in ${day}-${hr}${minuteplus_2}00 \
                   ${daym1h}-${hrm1}${minuteminus_2}00
  do
    file=RadarOnly_QPE_01H_00.00_${datestamp}.grib2.gz
    if [ -s $MRMSDIR/$file ]; then
      echo $MRMSDIR/$file >> file.list
    fi
  done

  let deltamin=$deltamin+1
done

