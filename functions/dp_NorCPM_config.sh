# 2015/01/15 by Mao-Lin Shen
set -e
CASEDIR=NorCPM_ME
Ensembles='1 2 3 4 5'
CaseConfig=ME
#dailymicom=yes
if [ "${CaseConfig}" == "ME" ] ; then
   GRIDPATH=/work/shared/noresm/inputdata/ocn/micom/gx1v6/20101119/grid.nc
   COMPSET=N20TREXTAERCN
   RES=f19_g16 
elif [ "${CaseConfig}" == "F19tn21" ] ; then
   GRIDPATH=/work/shared/noresm/inputdata/ocn/micom/tnx2v1/20130206/grid.nc
   COMPSET=N20TREXT
   RES=f19_tn21 
else
   GRIDPATH=/work/shared/noresm/inputdata/ocn/micom/tnx2v1/20130206/grid.nc
   COMPSET=N20TREXT
   RES=f19_tn21
#else
#   echo "$CASEDIR not implemented in NorCPM, we quit"
fi
VERSION=${CASEDIR}'_mem'


#FOLLOWING is related to the starting option
#If you are starting from the same model with same configuration set hybrib_run=0
####First Hybrid run possiblility :Ensemble start ####
#   an ensemble of run =same date multiple case name that finish by CASENAME_memXX
ens_start=1 #1 means we start hybrid from an ensemble run
ens_casename=noresm1_ME_hist_p01_mem
ens_start_date=1995-05-01-00000
branched_ens_date=1995-01-01-00000
####Second Hybrid run possiblility :Historical start ####
#   a historical run   =same case name multiple date (hist_start_date:hist_freq_date:NENS*hist_freq_date+hist_start_date)
hist_start=0 #1 means we start hybrid from anstorical run
#first member use year 0001 and then all member use year+5 
#TODO Not Finished
hist_start_date=1500
hist_freq_date=10


#FOLLOWING is related to the Reanalysis
SKIPASSIM=1
SKIPPROP=1
#start_date=1994-08-15-0000
the_start_date=1995-05-01-00000
short_start_date=`echo $the_start_date | cut -c1-10`
STARTMONTH=`echo $the_start_date | cut -c6-7`
STARTYEAR=`echo $the_start_date | cut -c1-4` 
#RFACTOR=0
RFACTOR=0
nbbatch=1
ENDYEAR=1994
export forecast_length=3
export WORKDIR HOMEDIR VERSION ENSSIZE
job_length=${forecast_length}

if [ "${machine}" == "hexagon_intel" ]; then
  if [ "${CaseConfig}" == "ME" ] ; then
#    (( resubmit = forecast_length / 1 ))
#    if [ ${job_length} -gt 1 ]; then
#      job_length=1
#    fi
    resubmit=0
    (( jobmins = 40 * job_length ))
    jobmins=${jobmins}
  elif [ "${CaseConfig}" == "F19tn21" ] ; then
    (( resubmit = forecast_length / 8 ))   
    if [ ${job_length} -gt 8 ]; then
      job_length=8
    fi
    jobmins=59
  else
    echo "Don't know what you mean"
  #else
  #   echo "$CASEDIR not implemented in NorCPM, we quit"
  fi
else
  echo "I did not test it yet"
  if [ "${CaseConfig}" == "ME" ] ; then
    (( jobmins = forecast_length * 20 + 6 ))
  elif [ "${CaseConfig}" == "F19tn21" ] ; then
    (( jobmins = forecast_length * 6 + 6 ))
  else
    echo "Don't know what you mean"
  #else
  #   echo "$CASEDIR not implemented in NorCPM, we quit"
  fi
  resubmit=0
fi



