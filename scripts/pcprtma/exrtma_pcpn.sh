#!/bin/sh
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
# $PDY and $cyc are exported in J-job.  pcpURMA to be processed is the current
# hour (unless running in retro - i.e. date0 set in LSF)
date0=${date0:-${PDY}${cyc}}

echo "--------------------------------------------"
echo " "Begin Precip RTMA analysis for $date0"    "
echo "--------------------------------------------"

########################################

day0=${date0:0:8}
hr0=${date0:8:2}

datem1h=`$NDATE -1 $date0`
daym1h=${datem1h:0:8}
hrm1=${datem1h:8:2}

cd $DATA

pwd

#######################################################################
# precip RTMA from MRMS RadarOnly_QPE_01H
#   The file is normally available every 2 minutes, with a 1-2 minute lag.
#   Files valid at the top-of-the-hour is usually available, and the 
#   other files files nearest the top of the hour are (e.g.) [hhmm):
#     1450, 1452, 1454, 1456, 1458 [1500], 1502, 1504, 1506, 1508, 1510. 
#   In case top-of-the-hour file is not available, each hour we'll make 
#     a list of all available files within +/-10 from the top of the hour, in 
#     order of valid time closest to the top of the hour.  For example, 
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-150000.grib2.gz
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-150200.grib2.gz
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-145800.grib2.gz
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-150400.grib2.gz
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-145600.grib2.gz
#                           ...........
#
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-151000.grib2.gz
#        MRMSQPEDIR/RadarOnly_QPE_01H_00.00_20190802-145000.grib2.gz
#
rm -f mrmsqpelist.$date0 mrmsrqilist.$date0

qpefile=RadarOnly_QPE_01H_00.00_${day0}-${hr0}0000.grib2.gz
rqifile=RadarQualityIndex_00.00_${day0}-${hr0}0000.grib2.gz
if [ -s $MRMSQPEDIR/$qpefile ]
then
  echo $qpefile > mrmsqpelist.$date0
fi

if [ -s $MRMSRQIDIR/$rqifile ]
then
  echo $rqifile > mrmsrqilist.$date0
fi

deltamin=1
while [ $deltamin -le 10 ];
do
  let minuteplus=$deltamin      # 01, 02, 03, ..., 10  
  let minuteminus=60-$deltamin  # 59, 58, 57, ..., 50

  # fill in leading zeros (so it'll be 01, 02, rather than 1, 2,...'
  minuteplus_2=`printf "%0*d\n" 2 $minuteplus`
  minuteminus_2=`printf "%0*d\n" 2 $minuteminus`
 
  for datestamp in ${day0}-${hr0}${minuteplus_2}00 \
                   ${daym1h}-${hrm1}${minuteminus_2}00
  do
    qpefile=RadarOnly_QPE_01H_00.00_${datestamp}.grib2.gz
    rqifile=RadarQualityIndex_00.00_${datestamp}.grib2.gz

    if [ -s $MRMSQPEDIR/$qpefile ]; then
      echo $qpefile >> mrmsqpelist.$date0
    fi

    if [ -s $MRMSRQIDIR/$rqifile ]; then
      echo $rqifile >> mrmsrqilist.$date0
    fi
  done

  let deltamin=$deltamin+1
done

echo mrmsqpelist.${date0}:
cat mrmsqpelist.${date0}
echo '  '
echo mrmsrqilist.${date0}:
cat mrmsrqilist.${date0}

# note that files from the list above already has the *.gz suffix.  Remove
# it for the 'rawmrms' below for ease of using $rawmrms in WGRIB2 command. 
# However, the head -1 ... | sed ... set up means that if the list doesn't
# exist, the line won't return a non-zero err code.  So we're checking for
# a non-empty list first.  

if [ ! -s mrmsqpelist.$date0 ]
then
  echo 'No MRMS QPE within +/-10min from top of $date0. Exit w/o making pcpRTMA'
  exit
fi

rawmrms=`head -1 mrmsqpelist.$date0 | sed 's/.gz//'`
cp $MRMSQPEDIR/$rawmrms.gz .
err=$?
if [ $err -eq 0 ]; then
  gunzip $rawmrms.gz
  
  # 1) use wgrib2 to process raw MRMS file:
  # see https://www.nco.ncep.noaa.gov/pmb/docs/grib2/grib2_doc/
  #
  #  argument   value   Notes
  #  rpn                Assign points with values of -3 as 'missing'
  #  table_1.2    1     significance of reference time: (start time of forecast)
  #                     '1' chosen to be consistent with previous pcprtma
  #  table_1.3    0     Production Status of Data (0 - operational products)
  #  table_1.4    1     Analysis and Forecast Products (value chosen to be 
  #                     consistent with previous pcprtma
  #  table_4.3    2     TYPE OF GENERATING PROCESS: TOCGRIB2 expects '2' - fcst
  #  table_4.11   2     TYPE OF TIME INTERVALS: ??
  #  analysis_or_forecast_process_id, changed from 152 (Stage II) to 109 (RTMA)
  #  set_date $datem1h  Starting time of the 1h accumulation period.  Need to 
  #                     set this, because if the MRMS valid at the top of the 
  #                     hour is missing and the closest MRMS file is from the 
  #                     previous hour (say hh:56, i.e. four minutes before the
  #                     top of the hour, then the valid time showing up in the
  #                     resulting processed grib file is the previous hour, i.e.
  #                     wgrib2 doesn't 'round up' to the closest whole hour.
  #                     So set_date to $datem1h so the valid time would be
  #                     the correct hour. 
  #
  # The following wgrib2 options have been tried but did not work 
  #   (per degrib2 and Jacob's pygrib inventory):
  #     -set master_table 2  - did not change master_table number
  #     -set local_table 1   - did not change local_table number
  #     -set_lev surface     - this would mess up the PRODUCT TEMPLATE 4. 8: 
  #                            (degrib2)

  #   2) Map the MRMS file from step 1 to ConUS grid 184
  #      also map the raw RQI to grid 184.  The RQI doesn't need all that 
  #      wgrib2 parameter manipulation because we're not sending it out
  #      to AWIPS. 
  $WGRIB2 -rpn "dup:-3:!=:mask" \
    -set center 7 -set subcenter 4 \
    -set analysis_or_forecast_process_id 109 \
    -set table_1.2 1 \
    -set table_1.3 0 \
    -set table_1.4 1 \
    -set table_4.3 2 \
    -set table_4.11 2 \
    -set_var APCP \
    -set_ftime "0-1 hour acc fcst" \
    -set_date $datem1h \
    -set_bitmap 1 -set_grib_type c1 \
     $rawmrms -grib_out mrms4rtma.$date0

# The 2.5km RTMA precip and the RQI: 
  rtmafile=pcprtma2.${date0}.grb2
  rtmarqi=rqirtma.${date0}.grb2

  WG2g184="lambert:265:25:25 238.445999:2145:2539.703 20.191999:1377:2539.703"
  WG2pack="c1 -set_bitmap 1"

# Map to 2.5km NDFD grid (g184):
  $WGRIB2 mrms4rtma.$date0 \
    -set_grib_type ${WG2pack} \
    -new_grid_winds grid \
    -new_grid_interpolation budget \
    -new_grid ${WG2g184} \
    $rtmafile

# Make a Stage II look-alike from the pcpRTMA:
#  $CNVGRIB -g21 $rtmafile $rtmafile.grb1
#  gridhrap="255 5 1121 881 23117 -119023 8 -105000 4763 4763 0 64"
#  $COPYGB -g "$gridhrap" -i3 -x $rtmafile.grb1 ST2ml${date0}.Grb
#  gzip ST2ml${date0}.Grb

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
  $TOCGRIB2 < $PARMrtma/grib2_pcprtma_g184
  export err=$?; echo "     err=$err"; err_chk
else 
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
   # exists for $date0)

# Now map the raw RQI file to g184:
# 
# note that files from mrmsrqilist.$date0 already has the *.gz suffix.  Remove
# it for the 'rawrqi' below for ease of using $rawrqi in WGRIB2 command. 
# Note that files from the list above already has the *.gz suffix.  Remove
# it for the 'rawmrms' below for ease of using $rawmrms in WGRIB2 command. 
# However, the head -1 ... | sed ... set up means that if the list doesn't
# exist, the line won't return a non-zero err code.  So we're checking for
# a non-empty list first.  

if [ ! -s mrmsrqilist.$date0 ]
then
  echo 'No MRMS RQI within +/-10min from top of $date0. Exit w/o making RQI for pcpRTMA'
  exit
fi

rawrqi=`head -1 mrmsrqilist.$date0 | sed 's/.gz//'`

cp $MRMSRQIDIR/$rawrqi.gz .
err=$?
if [ $err -eq 0 ]; then
  gunzip $rawrqi.gz

# Map to 2.5km NDFD grid (g184):
  $WGRIB2 $rawrqi \
    -set_grib_type ${WG2pack} \
    -new_grid_winds grid \
    -new_grid_interpolation neighbor \
    -new_grid ${WG2g184} \
    $rtmarqi
fi # if RQI file exists

if test $SENDCOM = 'YES'
then
  cp pcprtma2.${date0}.grb2 rqirtma.${date0}.grb2 $COMOUT/${RUN}.$day0/.
# cp ST2ml${date0}.Grb.gz $COMpcpanl/pcpanl.$day0/.
  cp grib2.t${cyc}z.awprtmapcp.184  $COMOUT/${RUN}.$day0/wmo/.
fi

if [ $SENDDBN = 'YES' ]; then
  $DBNROOT/bin/dbn_alert MODEL RTMA2P5PCP_GB2 $job $COMOUT/${RUN}.$day0/pcprtma2.${date0}.grb2
  #
  #      SEND RTMA PRECIP. GRIB@ FILE TO AWIPS
  #
  if [ "$SENDDBN_NTC" = 'YES' ]; then
      $DBNROOT/bin/dbn_alert GRIB_LOW $NET $job  $COMOUT/${RUN}.$day0/wmo/grib2.t${cyc}z.awprtmapcp.184
  fi
fi

  #####################################################################
  # GOOD RUN
  postmsg $jlogfile "$0 completed normally"
  #####################################################################


############## END OF SCRIPT #######################
