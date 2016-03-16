#! /bin/bash
###############################################################################
# for creating and monitoring decadal prediction run
# 15/01/2015 Mao-Lin Shen, create the scripts
#------------------------------------------------------------------------------
scripthome=`pwd`
pathStr=`echo ${scripthome}/functions | sed 's/\//\\\\\//g'`
sed -i s/"funcPath=".*/"funcPath=${pathStr}"/g DP_config.sh
  . ${scripthome}/DP_config.sh

set -ex
echo `date`

###############################################################################
# Check and prepare restart files
#------------------------------------------------------------------------------
###############################################################################
# Prediction start   
#------------------------------------------------------------------------------
for M_year in ${Prediction_years}; do
  . ${funcPath}/dp_func_naming_standard
  ${funcPath}/dp_func_check_job_Status "RES"
  ${funcPath}/dp_func_check_job_Status "CRE"

  if [ ! -d ${WORKDIR}/Logs ]; then
    mkdir -p ${WORKDIR}/Logs
  fi
exit 5
  #########################################################################
  # check prediction start months and restart file month   
  #------------------------------------------------------------------------
  is_restart_match=0
  if [ "${M_month}" == "${Analysis_restart_months}" ]; then
    is_restart_match=1
  fi

  set -e
  #########################################################################
  # rerun NorCPM if there is no restart files for prediction month
  #------------------------------------------------------------------------  
  if [ "${is_restart_match}" == "0"  ]; then
    echo "Configuration is not finished yet ...  "
    exit
    . ${funcPath}/dp_func_rerun_and_check_EnKF_SST
  fi

  set -e
  #########################################################################
  # Atmosphere nudging step in
  #------------------------------------------------------------------------
  if [ "${is_FOFA}" == "0" ]; then 
    . ${funcPath}/dp_func_atmosphere_nudging_only
  else
    echo "Configuration is not finished yet ...  "
    exit
    . ${funcPath}/dp_func_atmosphere_nudging_with_EnKF_SST
  fi
    
  set -e
  #########################################################################
  # Launch NorESM prediction 
  #------------------------------------------------------------------------
  . ${funcPath}/dp_func_Launch_prediction
  done

done # for prediction years
###############################################################################
# 
#------------------------------------------------------------------------------
if [ "${is_revisiting_jobs}" == "1" ]; then
  . ${funcPath}/dp_func_revisiting_jobs
fi

echo " Prediction integration is finished. "

