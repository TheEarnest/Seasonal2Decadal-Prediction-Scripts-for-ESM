#! /bin/bash
mailto="earnestshen@gmail.com"
#########################################################################
# Configurations for decadal prediction 
#------------------------------------------------------------------------
Prediction_expPrefix="SPtest" # for user only 
REST_CaseName="ana_19800115_me_mem"
Pred_CaseSuffix="p06" # new prediction name 
Prediction_start_date="01-15" # mm-dd
Prediction_length=1 # months
Analysis_restart_months="01"
Analysis_restart_day="15" # fixed by EnKF analysis
export CAM_Max_rlx=0.0020833333333333333 # maximum nudging coeff 
#export CAM_Max_rlx=0.08333333333333333 # maximum nudging coeff
is_FOFA=0; # free forecast  
#is_FOFA=1; # Initializing ocean fist and follow up with atmosphere nudging ...
#is_FOFA=2; # Initializing ocean and atmosphere together, for old analysis which we keep only forecast restart 
#is_FOFA=3; # Initializing ocean only ...

#########################################################################
# For ensemble configuration 
#------------------------------------------------------------------------
export ENSSIZE=3
nbbatch=8  #Number of group of job going into the queue
#export Prediction_ensembles="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 19 20 21 22 23 24 25 26 27 28 29 30 18"
export Prediction_ensembles="1 2 3";
export EnKF_ensembles=`seq 1 ${ENSSIZE}`
#RESTtar_path=/work/earnest/Conversion/noresm1_ME_hist_s01/analysis
#RESTtar_path=/cluster/work/users/earnest/wrk/ana_19800115_me
#RESTtar_path=/cluster/work/users/earnest/temp

RESTtar_path=/tos-project4/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V1/ana_19800115_me

#Prediction_years=`seq 1994 2009`
Prediction_years="1980 "

#FOLLOWING is related to the starting option
ens_casename=${REST_CaseName}
#########################################################################
# All background configuration 
#------------------------------------------------------------------------
export CaseModel=noresm1
export CaseForcing=hist
export CaseConfig=ME
Pred_CasePrefix=${CaseModel}"_"${CaseConfig}"_"${CaseForcing}"_"${Pred_CaseSuffix} # new prediction name 
export CPUACCOUNT=nn9385l
export CODEVERSION='noresm1-me'
REST_months="01 02 05 08 11"
export HOMEDIR=${HOME}/models/NorCPM/models
# funcPath will be updated by the main script automatically ...
export funcPath=/nird/home/earnest/Analysis/epocasa/Seasonal2Decadal_Prediction/functions
export rest_path="/cluster/work/users/${USER}/tmp/"${Prediction_expPrefix} #folder where data to be branched are temporarly stored
HPChost=`echo $HOST | cut -c1-7`
if [ "${HPChost}" == "hexagon" ]; then
  export machine='hexagon_intel'
  export WORKSHARED=/work/shared/nn9039k/NorCPM/
  export metdata_path=/work/shared/nn9039k/CAM_Nudging/met_data
elif [ "${HPChost}" == "service" ]; then
  export machine='vilje'
  export WORKSHARED=/work/earnest/nn9039k/NorCPM/
  export metdata_path=/work/earnest/nn9039k/CAM_Nudging/met_data
else
  export machine='fram'
  export WORKSHARED=/work/shared/nn9039k/NorCPM/
  export metdata_path=/work/shared/nn9039k/CAM_Nudging/met_data
fi

export NorCPM_config=${funcPath}"/dp_NorCPM_config.sh"
export CAMnudging_config=${funcPath}"/dp_SD_config.sh"
export Nudging_Exec_templet_CaseName="nudged_NorESM_${CaseConfig}_template_mem01"
export Normal_Exec_templet_CaseName="normal_NorCPM_${CaseConfig}_template_mem01"
export Nudging_SourceMods=dp_NudgingCase_SourceMods
export Normal_SourceMods=dp_NormalCase_SourceMods
export python=`which python`
Pmm=`echo ${Prediction_start_date} | cut -c1-2`
Pdd=`echo ${Prediction_start_date} | tail -c3 `
if [ "${Pmm}" -lt "${Analysis_restart_months}" ]; then 
  nudDays=`python ${funcPath}"/dp_func_checkdays.py" 1998 ${Analysis_restart_months} ${Analysis_restart_day} 1999 ${Pmm} ${Pdd} `
else
  nudDays=`python ${funcPath}"/dp_func_checkdays.py" 1998 ${Analysis_restart_months} ${Analysis_restart_day} 1998 ${Pmm} ${Pdd} `
fi

export nudging_length=${nudDays}"d" # d, day; m, month; y, year

export Log_Prefix=${Prediction_expPrefix}"_iOA"${is_FOFA}"_pn"${nudging_length}"_pL"${Prediction_length}
export Prediction_Prefix=${Pred_CasePrefix}
#  (( Prediction_months = Prediction_length + 1 ))
export Prediction_months=${Prediction_length}
export LinnBreaker="--------------------------------------------------------"
#########################################################################
# for system log
#------------------------------------------------------------------------
DebugSetting="set -ex"
is_revisiting_jobs=1
export prefix_mem="mem"
export prefix_Pyear="PSy"
export prefix_Pmonth="PSm"
export prefix_DAocean="DAO"
export prefix_CAMnudging="nAT"
export prefix_Prun="pRU"









