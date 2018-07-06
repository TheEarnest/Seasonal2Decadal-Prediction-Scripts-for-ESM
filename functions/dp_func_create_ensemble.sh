#!/bin/bash
#
${DebugSetting}
JobStartTime=`date`
JobName='dp_func_create_ensemble.sh'
#
echo ${LinnBreaker}
echo ${LinnBreaker}
echo "Starting "${JobName}" ...... "

tempPrefix=t_'dp_func_create_ensemble.sh'
###############################################################################



#This script will create an ensemble of folder of Noresm without duplicating Build directory.
#Francois Counillon 6/10/2011
. ${NorCPM_config}
start_date=${the_start_date}

let tmp_date=hist_start_date+hist_freq_date
hist_mem_date=`echo 000$tmp_date | tail -5c`
hist_mem01_date=`echo 000$hist_start_date | tail -5c`

if [ "${mem}" == "${firstmem}" ]; then
#Prepare member 1
cd ${HOMEDIR}/${CODEVERSION}/scripts
./create_newcase -case ${caseDIR}/${VERSION}${firstmem} -compset ${COMPSET} -res ${RES} -mach ${machine}
cd ${caseDIR}/${VERSION}${firstmem}

sed -i s/'module load xt-asyncpe'.*/'module load craype\/2.2.1 '/g env_mach_specific

./xmlchange -file env_run.xml -id LOGDIR -val ${WORKDIR}/${VERSION}${firstmem}/logs
./xmlchange -file env_build.xml -id EXEROOT -val ${WORKDIR}/${VERSION}${firstmem}
./xmlchange -file env_run.xml -id DOUT_S_ROOT -val ${ARCHIVE}/${VERSION}${firstmem}


./xmlchange -file env_run.xml -id STOP_OPTION -val nmonth
./xmlchange -file env_run.xml -id STOP_N -val ${job_length}
./xmlchange -file env_run.xml -id RESUBMIT -val ${resubmit}
./xmlchange -file env_run.xml -id RESTART -val 0
./xmlchange -file env_run.xml -id DIN_LOC_ROOT_CSMDATA -val /cluster/shared/noresm/inputdata
 ./xmlchange -file env_run.xml -id CONTINUE_RUN -val FALSE
 ./xmlchange -file env_conf.xml -id RUN_TYPE -val branch
 sed -i s/"time ftn".*/"time ftn  -traceback"/g Macros.${machine}
 short_ens_start_date=`echo $ens_start_date | cut -c1-10`
 ./xmlchange -file env_conf.xml -id RUN_STARTDATE -val $short_start_date
 ./xmlchange -file env_conf.xml -id RUN_REFDATE -val $short_ens_start_date
 ./xmlchange -file env_conf.xml -id RUN_REFCASE -val ${ens_casename}${firstmem}
  org_CAM_CONFIG_OPTS=`grep CAM_CONFIG_OPTS  env_conf.xml | awk -F "value=\"" '{print $2}' | awk -F "\" " '{print  $1}'`
  new_CAM_CONFIG_OPTS=${org_CAM_CONFIG_OPTS}"  -scen_rcp rcp85 "
  ./xmlchange -file env_conf.xml -id CAM_CONFIG_OPTS -val "${new_CAM_CONFIG_OPTS}"

 if ((${ens_casename}==${CASEDIR})); then
    ./xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
 fi

  templetePath=`readlink -f ${caseDIR}/../${Normal_Exec_templet_CaseName} `
#  the_EXEROOT=`grep "\"EXEROOT\"" env_build.xml | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' `
  cp -f ${templetePath}/env_build.xml env_build.xml
./xmlchange -file env_build.xml -id EXEROOT -val ${WORKDIR}/${VERSION}${firstmem}

./configure -case

. ${funcPath}/dp_func_HPC_job_update

cd ${caseDIR}/${VERSION}${firstmem}/Buildconf/
  micom_IDATE=`grep "IDATE    =" micom.buildnml.csh  | awk -F " " '{print $NF}'`
  micom_IDATE0=`grep "IDATE0   =" micom.buildnml.csh  | awk -F " " '{print $NF}'`
#MS cp ${funcPath}/dp_${CaseConfig}_NorESM_micom_buildnml_csh micom.buildnml.csh
  sed -i s/" RSTCMP   =".*/" RSTCMP   = 0"/g micom.buildnml.csh
  #MS#sed -i s/" IDATE    =".*/" IDATE    ="${micom_IDATE}/g micom.buildnml.csh
  #seMS#d -i s/" IDATE0   =".*/" IDATE0   ="${micom_IDATE0}/g micom.buildnml.csh

sed -i s/" RSTCMP   =".*/" RSTCMP   = 0"/g micom.buildnml.csh
sed -i s/"mfilt".*/"mfilt     = 1"/g cam.buildnml.csh
sed -i s/"nhtfrq".*/"nhtfrq    = -24"/g cam.buildnml.csh
sed -i s/" fincl2".*/"fincl2     = ' '"/g cam.buildnml.csh
sed -i s/"ncdata".*/"ncdata = ${ens_casename}${firstmem}.cam2.i.${branched_ens_date}.nc "/g cam.input_data_list
sed -i s/"ncdata".*/"ncdata     = '${ens_casename}${firstmem}.cam2.i.${branched_ens_date}.nc'"/g cam.buildnml.csh 

  cp -rfv ${funcPath}/${Normal_SourceMods}/* ${caseDIR}/${VERSION}${firstmem}/SourceMods/

cd ${caseDIR}/${VERSION}${firstmem}/
echo "Compiling the code, this will take some time"
./${VERSION}${firstmem}.${machine}.build
echo "Copying and extracting restart file"

#TODO copy restart and pointer
mkdir -p  ${rest_path}
#[ ! -f ${WORKSHARED}/Restart/${VERSION}_restart_${start_date}.tar.gz ] && { echo "Could not find restart file
#${WORKSHARED}/Restart/${VERSION}_restart_${start_date}.tar.gz; Look in Norstore " ; exit 1 ; }
cd ${rest_path}
#if [ ! -d "${ens_casename}30" ]; then
#  tar -xvof ${WORKSHARED}/Restart/${VERSION}_restart_${start_date}.tar.gz 
#fi
cp -f ${rest_path}/${ens_casename}${firstmem}/rest/${start_date}/${ens_casename}*.nc ${WORKDIR}/${VERSION}${firstmem}/run/
cp ${rest_path}/${ens_casename}${firstmem}/rest/${start_date}/rpointer.* ${WORKDIR}/${VERSION}${firstmem}/run/

EnKF_ensembles_left=`echo ${Prediction_ensembles} | cut -c3-1000`

# -----------------------------------------------------------------------
else

echo "Prepare the rest of the members"
#for i in ${EnKF_ensembles_left}; do
   mem=`echo 00${mem} | tail -3c`
   cd ${HOMEDIR}/${CODEVERSION}/scripts/
   ./create_newcase -case ${caseDIR}/${VERSION}${mem} -compset ${COMPSET} -res ${RES} -mach  ${machine}
   cd ${caseDIR}/${VERSION}${mem}
   cat ${caseDIR}/${VERSION}${firstmem}/env_conf.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_conf.xml
   cat ${caseDIR}/${VERSION}${firstmem}/env_run.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_run.xml
   cat ${caseDIR}/${VERSION}${firstmem}/env_build.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_build.xml
   sed -i s/'module load xt-asyncpe'.*/'module load craype\/2.2.1 '/g env_mach_specific
   ./configure -case
   sed '/ccsm_buildexe/d' ${VERSION}${mem}.${machine}.build > toto
   mv toto ${VERSION}${mem}.${machine}.build
   chmod 755 ${VERSION}${mem}.${machine}.build 
   rm -f ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh 
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/cam.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/temp_csh
   cat ${caseDIR}/${VERSION}${mem}/Buildconf/temp_csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh

   chmod 755 ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   rm -f ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/clm.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/temp_csh
   cat ${caseDIR}/${VERSION}${mem}/Buildconf/temp_csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   chmod 755 ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   cp ${caseDIR}/${VERSION}${firstmem}/Buildconf/micom.buildnml.csh  ${caseDIR}/${VERSION}${mem}/Buildconf/micom.buildnml.csh
   chmod 755  ${caseDIR}/${VERSION}${mem}/Buildconf/micom.buildnml.csh
   ${VERSION}${mem}.${machine}.build
   cat env_build.xml | sed  's/id="BUILD_COMPLETE"   value="FALSE"/id="BUILD_COMPLETE"   value="TRUE"/' > toto
   mv toto env_build.xml

   . ${funcPath}/dp_func_HPC_job_update

cp -rfv ${funcPath}/${Normal_SourceMods}/* ${caseDIR}/${VERSION}${mem}/SourceMods/

   echo 'Now setting up the work dir'
   cd ${WORKDIR}/${VERSION}${mem} 
   rm -rf atm cpl glc ice lib lnd ocn ccsm mct csm_share pio
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/atm ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/cpl ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/ccsm ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/csm_share ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/glc ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/ice ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/lib ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/lnd ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/mct ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/pio ${WORKDIR}/${VERSION}${mem}
   ln -sf ${WORKDIR}/${VERSION}${firstmem}/ocn ${WORKDIR}/${VERSION}${mem}
   cp ${WORKDIR}/${VERSION}${firstmem}/${VERSION}${firstmem}.ccsm.exe ${WORKDIR}/${VERSION}${mem}/${VERSION}${mem}.ccsm.exe
# limit the files copied .....
   mkdir -p ${WORKDIR}/${VERSION}${mem}/run
   cd ${WORKDIR}/${VERSION}${firstmem}/run
   fmemfns=`ls --color=no `
   for file in ${fmemfns} ; do
     fnsuffix=`echo ${file} | tail -c3 `
     if [ "${fnsuffix}" != "nc"  ]  ; then
       cp -rf  ${WORKDIR}/${VERSION}${firstmem}/run/${file} ${WORKDIR}/${VERSION}${mem}/run
     fi
   done

#   rm ${WORKDIR}/${VERSION}${mem}/run/${VERSION}${firstmem}*.nc
   cp ${WORKDIR}/${VERSION}${firstmem}/run/ccsm.exe ${WORKDIR}/${VERSION}${mem}/run/ccsm.exe
   if (( ${ens_start} )) ; then
      #rm -f ${WORKDIR}/${VERSION}${mem}/run/*.nc
      cp -f ${rest_path}/${ens_casename}${mem}/rest/${start_date}/${ens_casename}${mem}*.nc ${WORKDIR}/${VERSION}${mem}/run/
      cp ${rest_path}/${ens_casename}${mem}/rest/${start_date}/rpointer.* ${WORKDIR}/${VERSION}${mem}/run/

   fi

fi



###############################################################################
echo ${JobStartTime}
echo `date`" || "${JobName}
echo ${LinnBreaker}




