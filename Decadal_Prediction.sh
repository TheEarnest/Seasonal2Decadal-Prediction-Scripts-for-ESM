#! /bin/bash
###############################################################################
# for creating and monitoring decadal prediction run
# 15/01/2015 Mao-Lin Shen, create the scripts
#------------------------------------------------------------------------------
set -ex
scripthome=`pwd`
pathStr=`echo ${scripthome}/functions | sed 's/\//\\\\\//g'`
sed -i s/"funcPath=".*/"funcPath=${pathStr}"/g DP_config.sh
  . ${scripthome}/DP_config.sh
set -e

echo `date`

###############################################################################
# Check and prepare restart files
#------------------------------------------------------------------------------
set -e 
###############################################################################
# Prediction start   
#------------------------------------------------------------------------------
set -e 
for M_year in ${Prediction_years}; do
  export M_yr=`echo 000${M_year} | tail -5c`
  export M_month=${Analysis_restart_months}
  export Prediction_CaseName=${Prediction_Prefix}"_pM"${M_month}"_pY"${M_year}
  export M_mm=${M_month}
  export M_dd=${Analysis_restart_day}
  year=${M_year}

  export caseDIR=${HOMEDIR}/cases/${Prediction_CaseName}
  export WORKDIR=/work/${USER}/noresm/${Prediction_CaseName}
  export ARCHIVE=/work/${USER}/archive/${Prediction_CaseName}
  export ConversionDIR=/work/${USER}/Conversion/${Prediction_CaseName}
  export Prediction_sys_log=${ConversionDIR}/"sys_dp_"${Prediction_CaseName}

  ${funcPath}/dp_func_check_job_Status "RES"
  ${funcPath}/dp_func_check_job_Status "CRE"

  if [ ! -d ${WORKDIR}/Logs ]; then
    mkdir -p ${WORKDIR}/Logs
  fi

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
echo " Prediction integration is finished. "

