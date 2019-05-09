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
# $PDY and $cyc are exported in J-job.
date0=${PDY}${cyc}

echo "--------------------------------------------"
echo " "Begin Precip RTMA analysis for $date0"    "
echo "--------------------------------------------"
postmsg $jlogfile "Begin Precip RTMA analysis for $run version of $date0"

########################################

day0=`echo $date0 | cut -c1-8`

cd $DATA

pwd

# The mask will be used by both the RTMA and hourly ConUS URMA:
cp $FIXrtma/stage3_mask.grb .

#######################################################################
# precip RTMA: 
#   1) Combine early Stage II and first run Stage IV (if at least one exists)
#   2) Map the merged st2n4 file to the 2.5km and 5km ConUS NDFD grid 
#      for precip RTMA

ST2file=ST2ml${date0}.Grb
ST4file=ST4.${date0}.01h
st2n4file=st2n4.${date0}.01h

ST2exist=YES
cp $COMINpcpanl/pcpanl.$day0/$ST2file.gz .
if [ $? -eq 0 ]; 
then 
  gunzip $ST2file
else
  ST2exist=NO
fi

ST4exist=YES
cp $COMINpcpanl/pcpanl.$day0/$ST4file.gz .
if [ $? -eq 0 ]; then 
  gunzip $ST4file
else
  ST4exist=NO
fi

if [ $ST2exist = YES -o $ST4exist = YES ]; then
  RTMAmake=YES
else
  RTMAmake=NO
fi

if [ $RTMAmake = YES ]; then  # ST2 or ST4 (at least one) exists for this hour
  export pgm=pcprtma_merge2n4
  . prep_step
  ln -sf $ST2file                     fort.11
  ln -sf $ST4file                     fort.12
  ln -sf stage3_mask.grb              fort.13
  ln -sf $st2n4file                   fort.51
  ${EXECrtma}/pcprtma_merge2n4
  export err=$?; echo "     err=$err"; err_chk
  rm fort.11 fort.12 fort.13 fort.51

# The 2.5km RTMA precip:
  rtmafile=pcprtma2.${date0}.grb2

# Change the generating process number, PDS(2) from 152 (Stage II) to 109 
# (RTMA products):
  export pgm=pcprtma_changepds

  ln -sf $st2n4file                   fort.11
  ln -sf $st2n4file.chgdpds           fort.51

  $EXECrtma/pcprtma_changepds
  export err=$?; echo "     err=$err"; err_chk
  rm fort.11 fort.51

# Convert to GRIB2:
  $CNVGRIB -g12 $st2n4file.chgdpds ${st2n4file}.grb2

  NDFDgrid="30 1 0 6371200 0 0 0 0 2145 1377 20191999 238445999 8 25000000 265000000 2539703 2539703 0 64 25000000 25000000 0 0"

# Map to 2.5km NDFD grid:
  $COPYGB2 -g "$NDFDgrid" -i3 -x ${st2n4file}.grb2 $rtmafile

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
else  # neither ST2 or ST4 exists for this hour
  echo -e "WARNING: Neither Stage II/IV file exists for $date0, no RTMA\n" >>$DATA/emailmsg.txt

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
  postmsg $jlogfile "Neither Stage II/IV file exists for $date0, no RTMA"
  
fi # if we should make the RTMA file for this hour (i.e. either the ST2 or 
   # the ST4 file exists for this hour)


############## END OF SCRIPT #######################
