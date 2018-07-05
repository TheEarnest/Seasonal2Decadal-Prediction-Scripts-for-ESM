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
  . ${funcPath}/dp_func_naming_configuration
  ${funcPath}/dp_func_check_job_Status "RES"
  ${funcPath}/dp_func_check_job_Status "CRE"
  if [ ! -d ${WORKDIR}/../Logs ]; then
    mkdir -p ${WORKDIR}/../Logs
  fi

  #########################################################################
  # check prediction start months and restart file month   
  #------------------------------------------------------------------------
  is_restart_match=0
  if [ "${M_mm}" == "${Analysis_restart_months}" ]; then
    is_restart_match=1
  fi

  #########################################################################
  # rerun NorCPM if there is no restart files for prediction month
  #------------------------------------------------------------------------  
  if [ "${is_restart_match}" == "0"  ]; then
    echo "Configuration is not finished yet ...  "
    exit
    . ${funcPath}/dp_func_rerun_and_check_EnKF_SST
  fi

  #########################################################################
  # Atmosphere nudging step in
  #------------------------------------------------------------------------
  if [ "${is_FOFA}" == "0" ]; then
    echo "Start free forecasting ..."
    #. ${funcPath}/dp_func_free_forecasting 
  fi

  #########################################################################
  # Atmosphere nudging step in
  #------------------------------------------------------------------------
  if [ "${is_FOFA}" == "1" ]; then 
    echo "Start nudging run ..."
    . ${funcPath}/dp_func_atmosphere_nudging_only
  fi

  if [ "${is_FOFA}" == "2" ] || [ "${is_FOFA}" == "3" ]; then
    echo "Configuration is not finished yet ...  "
    exit
  fi

  #########################################################################
  # Launch NorESM prediction 
  #------------------------------------------------------------------------
  . ${funcPath}/dp_func_Launch_prediction_FOFA_${is_FOFA}

done # for prediction years
###############################################################################
# 
#------------------------------------------------------------------------------
set +x
if [ "${is_revisiting_jobs}" == "1" ]; then
  . ${funcPath}/dp_func_revisiting_jobs
fi

echo " Prediction integration is finished. "

