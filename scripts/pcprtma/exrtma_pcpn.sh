#!/bin/ksh
#######################################################################
#  Purpose: Produce current hour's precip RTMA field from erly Stage II
#    and first-run Stage IV (if available)
#######################################################################
#
# History:
# 2017/05/31 starting from pcpanl/scripts/expcpn_anal.sh, combine with
#   scripts/expcpn_stage4.sh to do post-pcpanl generation of pcp RTMA and URMA
#   fields.
# 
# 2017/07/06 Separate RTMA and URMA processing
#
#######################################################################

set -x

export JDATA=$DATA 
DATA=$DATA
mkdir -p $DATA
cd $DATA
# $PDY and $cyc are exported in J-job.  pcpURMA to be processed is the hour
# before (unless running in retro - i.e. date0 set in LSF)
date0=${date0:-`$NDATE -1 ${PDY}${cyc}`}

echo "--------------------------------------------"
echo " "Begin Precip RTMA analysis for $date0"    "
echo "--------------------------------------------"
postmsg $jlogfile "Begin Precip RTMA analysis for $run version of $date0"

########################################

day0=${date0:0:8}
hr0=${date0:8:2}

cd $DATA

pwd

#######################################################################
# precip RTMA from gauge QC'd MRMS:
#   1) use wgrib2 to process raw MRMS file:
#        - Assign points with values of -3 as 'missing'
#        - change field name to APCP
#        - change level type to "surface"
#        - Change 
#        - TBD: Change the generating process number, PDS(2) from 152 (Stage II)
#          to 109 (RTMA products):
#   2) Map the MRMS file from step 1 to ConUS grid 184
#
rawmrms=GaugeCorr_QPE_01H_00.00_${day0}-${hr0}0000.grib2
cp $MRMSDIR/$rawmrms.gz .
err=$?
if [ $err -eq 0 ]; then
  gunzip $rawmrms.gz
#  $WGRIB2 $rawmrms -rpn "dup:-3:!=:mask" -set_var APCP -set_lev surface -set_scaling -1 0 -set_bitmap 1 -set_grib_type c3 -grib_out mrms4rtma.$date0

$WGRIB2 -rpn "dup:-3:!=:mask" \
  -set center 7 -set subcenter 4 \
  -set local_table 1 \
  -set table_1.2 2 \
  -set table_1.4 0 \
  -set table_4.3 0 \
  -set table_4.11 2 \
  -set_var APCP -set_lev surface \
  -set_ftime "0-1 hour acc fcst" -set_date -1hr \
  -set_scaling -1 0 -set_bitmap 1 -set_grib_type c3 \
   $rawmrms -grib_out mrms4rtma.$date0


# The 2.5km RTMA precip:
  rtmafile=pcprtma2.${date0}.grb2

  NDFDgrid="30 1 0 6371200 0 0 0 0 2145 1377 20191999 238445999 8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 0 0"

# Map to 2.5km NDFD grid:
  $COPYGB2 -g "$NDFDgrid" -i3 -x mrms4rtma.$date0 $rtmafile

#####################################################################
#    Process PRECIP. RTMA FOR AWIPS
#####################################################################

# Process the 2.5km RTMA 
  export pgm=tocgrib2
  . prep_step
  export FORT11="$rtmafile"
  export FORT31=" "
  export FORT51="grib2.t${cyc}z.awprtmapcp.184"
  startmsg
# not working yet
#  $TOCGRIB2 < $PARMrtma/grib2_pcprtma_g184
#  export err=$?; echo "     err=$err"; err_chk

  if test $SENDCOM = 'YES'
  then
    cp pcprtma2.${date0}.grb2  $COMOUT/${RUN}.$day0/pcprtma2.${date0}.grb2
    cp grib2.t${cyc}z.awprtmapcp.184  $COMOUT/${RUN}.$day0/wmo/.
  fi

  if [ $SENDDBN = 'YES' ]; then
    $DBNROOT/bin/dbn_alert MODEL RTMA2P5PCP_GB2 $job $COMOUT/${RUN}.$day0/pcprtma2.${date0}.grb2
  #
  #      SEND RTMA PRECIP. GRIB@ FILE TO  AWIPS
  #
    if [ "$SENDDBN_NTC" = 'YES' ]; then
      $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job  $COMOUT/${RUN}.$day0/wmo/grib2.t${cyc}z.awprtmapcp.184
    fi
  fi

  #####################################################################
  # GOOD RUN
  postmsg $jlogfile "$0 completed normally"
  #####################################################################
else  # 
  echo -e "WARNING: failed to obtain MRMS file for $date0, no RTMA\n" >>$DATA/emailmsg.txt

  if [ "$envir" = "dev" ]; then 
    echo '############### NON-EMAIL ALERT #####################################'
    cat $DATA/emailmsg.txt
    echo '#####################################################################'
  else
    if [ -n "$MAILCC" ]; then
      mail.py -c $MAILCC ${MAILTO:?} $DATA/emailmsg.txt
    else
      mail.py < $DATA/emailmsg.txt
    fi
  fi 
  postmsg $jlogfile "Failed to obtain MRMS file for $date0, no RTMA"
  
fi # if we should make the RTMA file for this hour (i.e. if the MRMS file 
   $ exists for $date0)


############## END OF SCRIPT #######################
