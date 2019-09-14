#!/bin/sh
NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate
RTMAecf=/gpfs/dell2/emc/verification/noscrub/Ying.Lin/pcpanl/rtma.v2.8.0/suggested_LSF_settings/pcprtma
date1=2019090113
date2=2019090414

date=$date1

while [ $date -le $date2 ]
do
  $RTMAecf/PCPRTMA.tmp $date
  date=`$NDATE +1 $date`
done

exit

  

