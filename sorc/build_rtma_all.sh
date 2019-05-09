BASE=`pwd`
export BASE

cd $BASE

# partial build list
# set all to yes to compile all codes

export BUILD_pcprtma_changepds=yes
export BUILD_pcprtma_merge2n4=yes
export BUILD_rtma_firstguess=yes
export BUILD_rtma_gsianl=yes
export BUILD_rtma_post=yes

mkdir $BASE/logs
export logs_dir=$BASE/logs

. /usrx/local/Modules/default/init/ksh
module purge
module use -a ${BASE}/../modulefile
module load RTMA/v2.7.0

module list

sleep 1

##############################

if [ $BUILD_rtma_firstguess = yes ] ; then 

echo " .... Building rtma_firstguess .... "
./build_rtma_firstguess.sh > $logs_dir/build_rtma_firstguess.log 2>&1

fi

cd $BASE

##############################
  
if [ $BUILD_rtma_gsianl = yes ] ; then 

echo " .... Building rtma_gsi .... "
./build_rtma_gsianl.sh > $logs_dir/build_rtma_gsianl.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_rtma_post = yes ] ; then 

echo " .... Building post .... "
./build_rtma_post.sh > $logs_dir/build_rtma_post.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_pcprtma_changepds = yes ] ; then 

echo " .... Building pcprtma_changepds .... "
./build_pcprtma_changepds.sh > $logs_dir/build_pcprtma_changepds.log 2>&1

fi

cd $BASE

##############################

if [ $BUILD_pcprtma_merge2n4 = yes ] ; then 

echo " .... Building pcprtma_merge2n4 .... "
./build_pcprtma_merge2n4.sh > $logs_dir/build_pcprtma_merge2n4.log 2>&1
fi

cd $BASE

##############################
