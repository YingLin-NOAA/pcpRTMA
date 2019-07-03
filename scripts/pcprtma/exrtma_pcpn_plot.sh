#!/bin/ksh

#######################################################################
#    Plot the hour's RTMA analysis (legacy product; pcp urma files are
#    not plotted
#######################################################################
#
# Steps:
#   1. Prep; copy over the two GEMPAK fix files (coltbl.xwp.wbg, renamed
#      to coltbl.xwp, and g2varswmo2.tbl) 
#   2. Plot hourly precip RTMA

set -x

date0=`$NDATE -1 ${PDY}${cyc}`

export PLOTDIR=$DATA/plot

mkdir -p $PLOTDIR

cd $PLOTDIR

pgmout=out.$date0

# For a white background:
cp $GEMFIX/coltbl.xwp.wbg coltbl.xwp

# Missing value for precip set to -9999. so we can distinguish zero value 
# areas (plotted in vanilla) from no data areas (white):
cp $GEMFIX/g2varswmo2.tbl .

# Plot precip RTMA
RTMAFILE=pcprtma2.$date0.grb2
cp $COMIN/$RUN.$PDY/$RTMAFILE .
if [ -s $RTMAFILE ]; then
  $USHrtma/pcpn_plotpcp_grb2.sh $RTMAFILE pcprtma.$date0.gif $date0 01 "PCP RTMA"

  if [ $SENDCOM = 'YES' ]; then
    cp pcprtma.$date0.gif $COMOUT/$RUN.${date0:0:8}/.
    if [ $SENDDBN = 'YES' ]; then
      $DBNROOT/bin/dbn_alert MODEL PCPRTMA $job $COMOUT/$RUN.${date0:0:8}/pcprtma.$date0.gif 
    fi
  fi
fi
exit

