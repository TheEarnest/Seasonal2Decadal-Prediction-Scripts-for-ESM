#! /bin/ksh
# 2015/01/15 by Mao-Lin Shen

Ensembles='1'
CASEDIR='NorCPM_F19_tn21'
#CASEDIR='NorCPM_F19_tn21'
FN_CASEDIR='NorCPM_F19_tn21'
if [ "$CASEDIR" == "NorCPM_ME" ] ; then
   COMPSET=N20TREXTAERCN
   RES=f19_g16 
elif [ "$CASEDIR" == "SDNorCPM_F19tn21" ] ; then
   COMPSET=N20TREXT
   RES=f19_tn21 
else
   COMPSET=N20TREXT
   RES=f19_tn21
#else
#   echo "$CASEDIR not implemented in NorCPM, we quit"
fi
VERSION=${CASEDIR}'_mem'

#FOLLOWING is related to the starting option
ens_start=1 #1 means we start hybrid from an ensemble run
ens_casename='NorCPM_F19_tn21_mem'
ens_start_date=1970-01-01-00000
branched_ens_date=1970-01-01-00000
hist_start=0 #1 means we start hybrid from anstorical run
#first member use year 0001 and then all member use year+5 
#TODO Not Finished
hist_start_date=1500
hist_freq_date=10

the_start_date=1970-01-01-00000
short_start_date=`echo $the_start_date | cut -c1-10`
STARTMONTH=`echo $the_start_date | cut -c6-7`

