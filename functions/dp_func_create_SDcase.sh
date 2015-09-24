#!/bin/bash
# 2015/01/15 by Mao-Lin Shen
set -e

. ${CAMnudging_config}
start_date=${the_start_date}

#This script will create an ensemble of Noresm for atmosphere nudging 
# 2015/01/15 by Mao-Lin Shen
let tmp_date=hist_start_date+hist_freq_date
hist_mem_date=`echo 000${tmp_date} | tail -5c `
hist_mem01_date=`echo 000${hist_start_date} | tail -5c `
#Generate the script to convert output to netcdf4

if [ "${mem}" == "${firstmem}" ]; then
#Prepare member 1 
  cd ${HOMEDIR}/${CODEVERSION}/scripts
  create_newcase -case ${caseDIR}/${VERSION}${firstmem} -compset ${COMPSET} -res ${RES} -mach ${machine}
  mkdir -p ${WORKDIR}/${VERSION}${firstmem}/run
  time cp ${rest_path}/${ens_casename}${firstmem}/rest/${ens_start_date}/* ${WORKDIR}/${VERSION}${firstmem}/run & 

  cd ${caseDIR}/${VERSION}${firstmem}
#Avoid saving log file in your home folder
  xmlchange -file env_run.xml -id LOGDIR -val ${WORKDIR}/${VERSION}${firstmem}/logs
  xmlchange -file env_build.xml -id EXEROOT -val ${WORKDIR}/${VERSION}${firstmem}
  xmlchange -file env_run.xml -id DOUT_S_ROOT -val ${ARCHIVE}/${VERSION}${firstmem}
#Possible that you wish to integrate for 14 days for moving restart in the middle of the month
  nudging_period=`echo ${nudging_length} | sed 's/.$//'`  # 
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
  xmlchange -file env_conf.xml -id CAM_CONFIG_OPTS -val '-phys cam4 -scen_rcp rcp85 -offline_dyn ' 
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
    xmlchange -file env_conf.xml -id RUN_REFCASE -val ${ens_casename}${firstmem}
    if ((${ens_casename}==${CASEDIR})); then
       xmlchange -file env_conf.xml -id BRNCH_RETAIN_CASENAME -val TRUE
    fi
  fi
  sed -i s/'module load xt-asyncpe'.*/'module load craype\/2.2.1 '/g env_mach_specific
  configure -case
  sed -i s/"PBS -N ".*/"PBS -N r_SNESMt${firstmem}"/g    ${VERSION}${firstmem}.${machine}.run
  sed -i s/"PBS -A ".*/"PBS -A ${CPUACCOUNT}"/g     ${VERSION}${firstmem}.${machine}.run
  sed -i s/"PBS -l walltime".*/"PBS -l walltime=00:59:00"/g ${VERSION}${firstmem}.${machine}.run
  cd ${caseDIR}/${VERSION}${firstmem}/Buildconf/
  micom_IDATE=`grep "IDATE    =" micom.buildnml.csh  | awk -F " " '{print $NF}'`
  micom_IDATE0=`grep "IDATE0   =" micom.buildnml.csh  | awk -F " " '{print $NF}'`
  cp ${funcPath}/dp_NorESM_micom_buildnml_csh micom.buildnml.csh
  sed -i s/" IDATE    =".*/" IDATE    = "${micom_IDATE}/g micom.buildnml.csh
  sed -i s/" IDATE0   =".*/" IDATE0   = "${micom_IDATE0}/g micom.buildnml.csh
  sed -i s/" RSTCMP   =".*/" RSTCMP   = 0"/g micom.buildnml.csh
  sed -i s/"mfilt".*/"mfilt     = 1"/g cam.buildnml.csh
  sed -i s/"nhtfrq".*/"nhtfrq    = 0"/g cam.buildnml.csh
  #sed -i s/"nhtfrq".*/"nhtfrq    = -24"/g cam.buildnml.csh
  sed -i s/" fincl2".*/"fincl2     = ' '"/g cam.buildnml.csh
  sed -i s/"ncdata".*/"ncdata = ${ens_casename}${firstmem}.cam2.i.${branched_ens_date}.nc "/g cam.input_data_list
  sed -i s/"ncdata".*/"ncdata     = '${ens_casename}${firstmem}.cam2.i.${branched_ens_date}.nc'"/g cam.buildnml.csh
  sed -i s/"finidat".*/"finidat     = '${ens_casename}${firstmem}.clm2.r.${ens_start_date}.nc'"/g clm.buildnml.csh 
  sed -i s/"finidat".*/"finidat = '${ens_casename}${firstmem}.clm2.r.${ens_start_date}.nc' "/g clm.input_data_list
  sed -i s/"ice_ic".*/"ice_ic     = '${ens_casename}${firstmem}.cice.r.${ens_start_date}.nc'"/g cice.buildnml.csh
  insertLN=`grep -n "nhtfrq" cam.buildnml.csh | awk -F ":" '{print $1}' `

  cp ${HOMEDIR}/Script/functions/CAML26_nudging_namelist CAML26_nudging_namelist
  yyCAM=`echo ${start_date} | awk -F "-" '{print $1}'`
  mmCAM=`echo ${start_date} | awk -F "-" '{print $2}'`
  sed -i s/"#nuYEAR"/"${yyCAM}"/g CAML26_nudging_namelist
  sed -i s/"#nuMONTH"/"${mmCAM}"/g CAML26_nudging_namelist

  met_path=`echo "${metdata_path}" | sed 's/\//\\\\\//g'`
  sed -i s/"#nuPath"/"${met_path}"/g CAML26_nudging_namelist
  sed -i s/"#CAM_Max_rlx"/"${CAM_Max_rlx}"/g CAML26_nudging_namelist

  sed -i "${insertLN} r CAML26_nudging_namelist" cam.buildnml.csh
  cp ${HOMEDIR}/Script/functions/CAMnudging_metdata.F90 ${caseDIR}/${VERSION}${firstmem}/SourceMods/src.cam/metdata.F90
  cp ${HOMEDIR}/Script/functions/CAMnudging_cam_comp.F90 ${caseDIR}/${VERSION}${firstmem}/SourceMods/src.cam/cam_comp.F90

  cp ${HOMEDIR}/Script/functions/CAMnudging_runtime_opts.F90 ${caseDIR}/${VERSION}${firstmem}/SourceMods/src.cam/runtime_opts.F90


  cd ${caseDIR}/${VERSION}${firstmem}/
  echo "Compiling the code, this will take some time"
  #${VERSION}${firstmem}.${machine}.clean_build

  temp_dateS=`date`
  ${VERSION}${firstmem}.${machine}.build
  echo ${temp_dateS}
  echo `date`

  cd ${WORKDIR}/${VERSION}${firstmem}/run

# -----------------------------------------------------------------------
else
echo "Prepare the rest of the members"
#Prediction_ensembles_left=`echo ${Prediction_ensembles} | cut -c3-1000`

#for i in ${Prediction_ensembles_left}; do
#   mem=`echo 0$i | tail -3c`
   cd ${HOMEDIR}/${CODEVERSION}/scripts/
   create_newcase -case ${caseDIR}/${VERSION}${mem} -compset ${COMPSET} -res ${RES} -mach  ${machine}
   cd ${caseDIR}/${VERSION}${mem}
   cat ${caseDIR}/${VERSION}${firstmem}/env_conf.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_conf.xml
   cat ${caseDIR}/${VERSION}${firstmem}/env_run.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_run.xml
   cat ${caseDIR}/${VERSION}${firstmem}/env_build.xml | sed  "s/mem${firstmem}/mem${mem}/" > toto
      mv toto env_build.xml
   sed -i s/'module load xt-asyncpe'.*/'module load craype\/2.2.1 '/g env_mach_specific

   configure -case
   sed '/ccsm_buildexe/d' ${VERSION}${mem}.${machine}.build > toto
   mv toto ${VERSION}${mem}.${machine}.build
   chmod 755 ${VERSION}${mem}.${machine}.build
   rm -f ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/cam.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/cam.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   sed -i s/mem${firstmem}/mem${mem}/g ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   chmod 755 ${caseDIR}/${VERSION}${mem}/Buildconf/cam.buildnml.csh
   rm -f ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/clm.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   cat ${caseDIR}/${VERSION}${firstmem}/Buildconf/clm.buildnml.csh | sed  "s/mem${firstmem}/mem${mem}/" > ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   sed -i s/mem${firstmem}/mem${mem}/g  ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   chmod 755 ${caseDIR}/${VERSION}${mem}/Buildconf/clm.buildnml.csh
   cp ${caseDIR}/${VERSION}${firstmem}/Buildconf/micom.buildnml.csh  ${caseDIR}/${VERSION}${mem}/Buildconf/micom.buildnml.csh
   chmod 755  ${caseDIR}/${VERSION}${mem}/Buildconf/micom.buildnml.csh
   ${VERSION}${mem}.${machine}.build
   cat env_build.xml | sed  's/id="BUILD_COMPLETE"   value="FALSE"/id="BUILD_COMPLETE"   value="TRUE"/' > toto
   mv toto env_build.xml
#sed -i s/"PBS -N ".*/"PBS -N r_SDNESM_t01"/g          ${VERSION}01.${machine}.run
   sed -i s/"PBS -N ".*/"PBS -N r_SNESMt${mem}"/g  ${VERSION}${mem}.${machine}.run
   sed -i s/"PBS -A ".*/"PBS -A ${CPUACCOUNT}"/g     ${VERSION}${mem}.${machine}.run
   sed -i s/"PBS -l walltime".*/"PBS -l walltime=00:59:00"/g ${VERSION}${mem}.${machine}.run

   echo 'Now setting up the work dir'
   cp ${HOMEDIR}/Script/functions/CAMnudging_metdata.F90 ${caseDIR}/${VERSION}${mem}/SourceMods/src.cam/metdata.F90
   cp ${HOMEDIR}/Script/functions/CAMnudging_cam_comp.F90 ${caseDIR}/${VERSION}${mem}/SourceMods/src.cam/cam_comp.F90

   cp ${HOMEDIR}/Script/functions/CAMnudging_runtime_opts.F90 ${caseDIR}/${VERSION}${mem}/SourceMods/src.cam/runtime_opts.F90

   cd ${WORKDIR}/${VERSION}${mem}
   rm -rf atm cpl glc ice lib lnd ocn ccsm mct csm_share pio
   ln -s ${WORKDIR}/${VERSION}${firstmem}/atm ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/cpl ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/ccsm ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/csm_share ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/glc ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/ice ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/lib ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/lnd ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/mct ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/pio ${WORKDIR}/${VERSION}${mem}
   ln -s ${WORKDIR}/${VERSION}${firstmem}/ocn ${WORKDIR}/${VERSION}${mem}
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

   cp ${WORKDIR}/${VERSION}${firstmem}/run/ccsm.exe ${WORKDIR}/${VERSION}${mem}/run/ccsm.exe
   if (( ${ens_start} )) ; then
      #rm -f ${WORKDIR}/${VERSION}${mem}/run/*.nc
      #ln -sf ${rest_path}/${ens_casename}${mem}/rest/${start_date}/*.nc ${WORKDIR}/${VERSION}${mem}/run/
      #cp ${rest_path}/${ens_casename}${mem}/rest/${start_date}/rpointer.* ${WORKDIR}/${VERSION}${mem}/run/

echo ${start_date}
      cp ${rest_path}/${ens_casename}${mem}/rest/${start_date}/* ${WORKDIR}/${VERSION}${mem}/run/
      cd ${WORKDIR}/${VERSION}${mem}/run
  #    micom_old_rest=`ls ${ens_casename}${mem}*micom*  ` 
  #    micom_old_rest_suffix=`echo  ${micom_old_rest} | awk -F "micom" '{print $2}'`
  #    ln -sf ${micom_old_rest} ${VERSION}${mem}.micom${micom_old_rest_suffix}
   fi
fi

############################################################################
# namelist params for offline_dyn metdata input
# met_data_file
# met_data_path
# met_remove_file
# met_cell_wall_winds
# met_filenames_list
# met_rlx_top (in km)
# met_rlx_bot (in km)
# met_max_rlx
# met_fix_mass
# met_shflx_name
# met_shflx_factor
# met_qflx_name
# met_qflx_factor

#! met_data_file        name of file that contains the offline meteorology data
#! met_data_path        name of directory that contains the offline meteorology data
#! met_filenames_list   name of file that contains names of the offline 
#!                      meteorology data files
#! met_remove_file      true => the offline meteorology file will be removed
#! met_cell_wall_winds  true => the offline meteorology winds are defined on the model grid cell walls
###if ( defined OFFLINE_DYN )
#  ! offline meteorology parameters
#  namelist /cam_inparm/ met_data_file, met_data_path, met_remove_file, met_cell_wall_winds, &
#                        met_filenames_list, met_rlx_top, met_rlx_bot, met_max_rlx, &
#                        met_fix_mass, met_shflx_name, met_qflx_name, &
#                        met_shflx_factor, met_qflx_factor
##endif





#Edit Buildconf/cpl.buildnml.csh. Replace existing brnch_retain_casename line with the following line brnch_retain_casename = .true.

#Edit Buildconf/cam.buildnml.csh. Check that bndtvghg = '$DIN_LOC_ROOT' and add:

#&cam_inparm 
#       doisccp = .true.        
#       isccpdata = '/fis/cgd/cseg/csm/inputdata/atm/cam/rad/isccp.tautab_invtau.nc'        
#       mfilt   = 1,365,30,120,240        
#       nhtfrq  = 0,-24,-24,-6,-3        
#       fincl2  = 'TREFHTMN','TREFHTMX','TREFHT','PRECC','PRECL','PSL'        
#       fincl3  = 'CLDICE','CLDLIQ','CLDTOT','CLOUD','CMFMC','CMFMCDZM','FISCCP1',        
#                 'FLDS','FLDSC','FLNS','FLUT','FLUTC','FSDS','FSDSC','FSNS',        
#                 'FSNSC','FSNTOA','FSNTOAC','LHFLX','OMEGA','OMEGA500',         
#                 'PRECSC','PRECSL','PS','Q','QREFHT','RELHUM','RHREFHT','SHFLX',        
#                 'SOLIN','T','TGCLDIWP','TGCLDLWP','U','V','Z3'        
#       fincl4  = 'PS:I','PSL:I','Q:I','T:I','U:I','V:I','Z3:I'        
#       fincl5  = 'CLDTOT','FLDS','FLDSC','FLNS','FLNSC','FSDS','FSDSC','FSNS',        
#                 'LHFLX','PRECC','PRECL','PRECSC','PRECSL','SHFLX',        
#                 'PS:I','QREFHT:I','TREFHT:I','TS:I'        
#                  /
#
