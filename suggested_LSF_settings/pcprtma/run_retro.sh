#!/bin/sh
NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate
RTMAecf=/gpfs/dell2/emc/verification/noscrub/Ying.Lin/pcpanl/rtma.v2.8.0/suggested_LSF_settings/pcprtma
date1=2019073113
date2=2019082612

date=$date2

while [ $date -ge $date1 ]
do
  $RTMAecf/PCPRTMA.tmp $date
  date=`$NDATE -1 $date`
done

exit

  

