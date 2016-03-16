#!/bin/bash
# 2015/01/15 by Mao-Lin Shen
set -e

. ${CAMnudging_config}
ENSSIZE=1
CASEDIR=`echo ${Nudging_Exec_templet_CaseName} | awk -F "_mem" '{print $1}'`
VERSION01=${Nudging_Exec_templet_CaseName}
start_date=${the_start_date}
nudcaseDIR=`readlink -f ${caseDIR}/../ `
nudWORKDIR=`readlink -f ${WORKDIR}/../ `

#This script will create an ensemble of Noresm for atmosphere nudging 
# 2015/01/15 by Mao-Lin Shen
if [ -d ${nudcaseDIR}/${VERSION01} ]; then
  rm -rf ${nudcaseDIR}/${VERSION01}
fi
let tmp_date=hist_start_date+hist_freq_date
hist_mem_date=`echo 000$tmp_date | tail -5c`
hist_mem01_date=`echo 000$hist_start_date | tail -5c`

cd ${HOMEDIR}/${CODEVERSION}/scripts
create_newcase -case ${nudcaseDIR}/${VERSION01} -compset ${COMPSET} -res ${RES} -mach ${machine}
cd ${nudcaseDIR}/${VERSION01}
#Avoid saving log file in your home folder
xmlchange -file env_run.xml -id LOGDIR -val ${nudWORKDIR}/${VERSION01}/logs
xmlchange -file env_build.xml -id EXEROOT -val ${nudWORKDIR}/${VERSION01}
xmlchange -file env_run.xml -id DOUT_S_ROOT -val ${ARCHIVE}/${VERSION01}
#Possible that you wish to integrate for 14 days for moving restart in the middle of the month
nudging_period=`echo ${nudging_length} | sed 's/.$//'`
nudging_base=`echo ${nudging_length} | tail -c2`
if [ "${nudging_base}" == "d" ]; then
  xmlchange -file env_run.xml -id STOP_OPTION -val nday
elif [ "${nudging_base}" == "m" ]; then
  xmlchange -file env_run.xml -id STOP_OPTION -val nmonth
elif [ "${nudging_base}" == "y" ]; then
  xmlchange -file env_run.xml -id STOP_OPTION -val nyear
else
  xmlchange -file env_run.xml -id STOP_OPTION -val nmonth
fi
xmlchange -file env_run.xml -id STOP_N -val ${nudging_period}
xmlchange -file env_run.xml -id RESUBMIT -val 0
xmlchange -file env_run.xml -id RESTART -val 0
org_CAM_CONFIG_OPTS=`grep CAM_CONFIG_OPTS  env_conf.xml | awk -F "value=\"" '{print $2}' | awk -F "\" " '{print  $1}'`
new_CAM_CONFIG_OPTS=${org_CAM_CONFIG_OPTS}" -offline_dyn "
xmlchange -file env_conf.xml -id CAM_CONFIG_OPTS -val "${new_CAM_CONFIG_OPTS}" 
xmlchange -file env_run.xml -id CONTINUE_RUN -val FALSE
#xmlchange -file env_conf.xml -id RUN_TYPE -val hybrid
xmlchange -file env_conf.xml -id RUN_TYPE -val branch
sed -i s/"time ftn".*/"time ftn  -traceback"/g Macros.${machine}

if ((${hist_start})) ; then
  echo "Not yet implemented"; exit 0;
elif ((${ens_start})) ; then
  short_ens_start_date=`echo $ens_start_date | cut -c1-10`
  xmlchange -file env_conf.xml -id RUN_STARTDATE -val $short_start_date
  xmlchange -file env_conf.xml -id RUN_REFDATE -val $short_ens_start_date
  xmlchange -file env_conf.xml -id RUN_REFCASE -val ${ens_casename}01
  if ((${ens_casename}==${CASEDIR})); then
     xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
  fi
fi
sed -i s/'module load xt-asyncpe'.*/'module load craype\/2.2.1 '/g env_mach_specific
configure -case
sed -i s/"PBS -N ".*/"PBS -N r_SNESMt01"/g          ${VERSION01}.${machine}.run
sed -i s/"PBS -A ".*/"PBS -A ${CPUACCOUNT}"/g     ${VERSION01}.${machine}.run
sed -i s/"PBS -l walltime".*/"PBS -l walltime=00:59:00"/g ${VERSION01}.${machine}.run
cd ${nudcaseDIR}/${VERSION01}/Buildconf/
sed -i s/" RSTCMP   =".*/" RSTCMP   = 0"/g micom.buildnml.csh
sed -i s/"mfilt".*/"mfilt     = 1"/g cam.buildnml.csh
sed -i s/"nhtfrq".*/"nhtfrq    = 0"/g cam.buildnml.csh
#sed -i s/"nhtfrq".*/"nhtfrq    = -24"/g cam.buildnml.csh
sed -i s/" fincl2".*/"fincl2     = ' '"/g cam.buildnml.csh
sed -i s/"ncdata".*/"ncdata = ${ens_casename}01.cam2.i.${branched_ens_date}.nc "/g cam.input_data_list
sed -i s/"ncdata".*/"ncdata     = '${ens_casename}01.cam2.i.${branched_ens_date}.nc'"/g cam.buildnml.csh
sed -i s/"finidat".*/"finidat     = '${ens_casename}01.clm2.r.${ens_start_date}.nc'"/g clm.buildnml.csh 
sed -i s/"finidat".*/"finidat = '${ens_casename}01.clm2.r.${ens_start_date}.nc' "/g clm.input_data_list
sed -i s/"ice_ic".*/"ice_ic     = '${ens_casename}01.cice.r.${ens_start_date}.nc'"/g cice.buildnml.csh
insertLN=`grep -n "nhtfrq" cam.buildnml.csh | awk -F ":" '{print $1}' `

cp ${funcPath}/CAML26_nudging_namelist CAML26_nudging_namelist
yyCAM=`echo ${start_date} | awk -F "-" '{print $1}'`
mmCAM=`echo ${start_date} | awk -F "-" '{print $2}'`
sed -i s/"#nuYEAR"/"${yyCAM}"/g CAML26_nudging_namelist
sed -i s/"#nuMONTH"/"${mmCAM}"/g CAML26_nudging_namelist

met_path=`echo "${metdata_path}" | sed 's/\//\\\\\//g'`
sed -i s/"#nuPath"/"${met_path}"/g CAML26_nudging_namelist
sed -i s/"#CAM_Max_rlx"/"${CAM_Max_rlx}"/g CAML26_nudging_namelist

sed -i "${insertLN} r CAML26_nudging_namelist" cam.buildnml.csh
cp ${funcPath}/CAMnudging_metdata.F90 ${nudcaseDIR}/${VERSION01}/SourceMods/src.cam/metdata.F90
cp ${funcPath}/CAMnudging_cam_comp.F90 ${nudcaseDIR}/${VERSION01}/SourceMods/src.cam/cam_comp.F90

cp ${funcPath}/CAMnudging_runtime_opts.F90 ${nudcaseDIR}/${VERSION01}/SourceMods/src.cam/runtime_opts.F90

# 
############################################################################
cd ${nudcaseDIR}/${VERSION01}/
echo "Compiling the code, this will take some time"
${VERSION01}.${machine}.build


