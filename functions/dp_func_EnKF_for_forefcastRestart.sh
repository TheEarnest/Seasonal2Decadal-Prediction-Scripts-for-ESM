#!/bin/bash -x

#
${DebugSetting}
JobStartTime=`date`
JobName='dp_func_template'
# 
echo ${LinnBreaker}
echo ${LinnBreaker}
echo "Starting "${JobName}" ...... "

tempPrefix=t_'dp_func_template'
###############################################################################

MainScript=Decadal_Prediction.sh
if [ ! -f ${MainScript} ]; then
  cd ..
fi
scripthome=`pwd`
. ${scripthome}/DP_config.sh
. ${CAMnudging_config}
export ENSSIZE=30

RESTtar_path=${RESTtar_path}_b4DA

#===============================================================================
for M_year in ${Prediction_years}; do
  . ${funcPath}/dp_func_naming_configuration
  WORKDIR=${rest_path}/re_enkf_analysis
  rest_path=${rest_path}/re_enkf_analysis
  if [ ! -d ${WORKDIR}/ANALYSIS/ ] ; then
        mkdir -p ${WORKDIR}/ANALYSIS  || { echo "Could not create ANALYSIS dir" ; exit 1 ; }
  fi
  EnKF_ensembles=`seq -w 1 30`
  yr=${M_yr};mm=${M_mm} 
  for mem in ${EnKF_ensembles} ; do
    echo "Check restart files for member "${mem}
    . ${funcPath}/dp_func_untar_and_check_restartF
  done



  year=${M_yr}; month=${M_mm}

  mm=`echo 0$month | tail -3c`
  yr=`echo 000$year | tail -5c`
  yr_assim=`echo 000$year | tail -5c`
  echo 'model is at:' $year $month
  echo 'observation is at:' $yr_assim $month
  cd ${WORKDIR}/ANALYSIS/
  for iobs in ${!OBSLIST[*]};    do
    OBSTYPE=${OBSLIST[$iobs]}
    PRODUCER=${PRODUCERLIST[$iobs]}
    MONTHLY=${MONTHLY_ANOM[$iobs]}

    ln -sf ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/${yr_assim}_${mm}.nc  .  || { echo "${WORKDIR}/OBS/${OBSTYPE}/${PRODUCER}/${yr_assim}_${mm}.nc, we quit" | mail -s "`date`:  ${WORKDIR}/OBS/${OBSTYPE}/${PRODUCER}/${yr_assim}_${mm}.nc, we quit" earnestshen@gmail.com  exit 1 ; }
pakPrefix=`echo "${ens_casename}" | awk -F "_mem" '{print $1}'`

    if (( ${ANOMALYASSIM} )) ;  then
      ln -sf ${WORKSHARED}/bin/prep_obs_anom prep_obs
      if (( ${SUPERLAYER} )) ;  then
        ln -sf ${WORKSHARED}/bin/EnKF_Yiguo_anom_no_copy EnKF
      else
        ln -sf ${WORKSHARED}/bin/EnKF_anom EnKF
      fi
      ln -sf ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/${OBSTYPE}_avg_${mm}-${REF_PERIOD}.nc mean_obs.nc || { echo "Error ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/SST_avg_${mm}.nc missing, we quit" ; exit 1 ; }
      ln -sf ${WORKSHARED}/Input/NorESM/${pakPrefix}_${PRODUCER}_anom/Free-average${mm}-${REF_PERIOD}.nc mean_mod.nc || { echo "Error ${WORKSHARED}/Input/NorESM/${pakPrefix}_${PRODUCER}_anom/${OBSTYPE}_ave-${mm}.nc  missing, we quit" ; exit 1 ; }
     else
       ln -sf ${WORKSHARED}/bin/prep_obs_FF prep_obs
       if (( ${SUPERLAYER} )) ;      then
         ln -sf /home/uib/earnest/NorESM/bin/EnKF_Yiguo_FF EnKF
       else
         ln -sf ${HOMEDIR}/bin/EnKF_FF EnKF
       fi
       ln -sf ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/${OBSTYPE}_avg_${mm}-${REF_PERIOD}.nc mean_obs.nc || { echo "Error ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/SST_avg_${mm}.nc missing, we quit" ; exit 1 ; }
       ln -sf ${WORKSHARED}/Input/NorESM/${CASEDIR}_${PRODUCER}_anom/Free-average${mm}-${REF_PERIOD}.nc mean_mod.nc || { echo "Error ${WORKSHARED}/Input/NorESM/${CASEDIR}_${PRODUCER}_anom/${OBSTYPE}_ave-${mm}.nc  missing, we quit" ; exit 1 ; }

     fi
     cat ${WORKSHARED}/Input/EnKF/infile.data.${OBSTYPE}.${PRODUCER} | sed  "s/yyyy/${yr_assim}/" | sed  "s/mm/${mm}/" > infile.data
     ln -sf  $GRIDPATH .
     #${WORKSHARED}/Script/Link_forecast_nocopy.sh ${yr} ${month}
     export REST_CaseName=${REST_CaseName}
     ${funcPath}/dp_func_Link_forecast_nocopy.sh ${yr} ${month}

     ./prep_obs 
     ln -sf ${WORKSHARED}/bin/ensave .
     cat /home/uib/earnest/NorESM/EnKF_Script/pbs_enkf.sh_nocopy_mal | sed  "s/NENS/${ENSSIZE}/" | sed  "s/nnXXXXk/${CPUACCOUNT}/"  > pbs_enkf.sh
     WORK_Analysis=`echo ${WORKDIR}/ANALYSIS | sed 's/\//\\\\\//g'`
     sed -i s/"cd  \/work".*/"cd ${WORK_Analysis}"/g pbs_enkf.sh
     chmod 755 pbs_enkf.sh
     cp  -f ${WORKSHARED}/Input/EnKF/analysisfields.in .
     cat ${WORKSHARED}/Input/EnKF/enkf.prm_mal | sed  "s/XXX/${RFACTOR}/" > enkf.prm
     sed -i s/"enssize =".*/"enssize = "${ENSSIZE}/g enkf.prm
     #launch EnKF
     set -e 
     enkfid=`qsub ./pbs_enkf.sh`

     sleep 1s
     enkfans="R"
     while ( [ "${enkfans}" == "Q" ] || [ "${enkfans}" == "R" ] ) ; do
       enkfans=`qstat ${enkfid} 2>/dev/null | tail -n 1 | awk '{print $5}'`
       echo "waiting for EnKF-SST"
       sleep 5s
     done
     set +e
     cd ${WORKDIR}/ANALYSIS
     ans=`diff forecast_avg.nc analysis_avg.nc`
     if [ -z "${ans}" ] ;   then
       echo "There has been no update, we quit!!" | mail -s "`date`: There has been no update, we quit!!" earnestshen@gmail.com
       exit 1
     fi
     echo 'Finished with EnKF; start post processing'
     date
     cat ${HOME}/NorESM/EnKF_Script/fixenkf_${RES}_v3.sh_mal | sed  "s/NENS/${ENSSIZE}/g"  > fixenkf.sh
     sed -i s/"cd \/work".*/"cd ${WORK_Analysis}"/g fixenkf.sh
     chmod 755 fixenkf.sh
     ln -sf ${WORKSHARED}bin/micom_serial_init_${RES}-16-nocopy   micom_serial_init
     ln -sf ${WORKSHARED}/bin/launcher${ENSSIZE} launcher
     if [ ! -d ${WORKDIR}/RESULT/ ] ; then
       mkdir -p ${WORKDIR}/RESULT  || { echo "Could not create RESULT dir" ; exit 1 ; }
     fi
     if [ ! -d ${WORKDIR}/RESULT/${yr}_${mm} ] ; then
       mkdir -p ${WORKDIR}/RESULT/${yr}_${mm}  || { echo "Could not create RESULT/${yr}_${mm} dir" ; exit 1 ; }
     fi
     cd ${WORKDIR}/ANALYSIS/
     mv enkf_diag.nc analysis_*.nc forecast_avg.nc observations-SST.nc ensstat_field.nc ${WORKDIR}/RESULT/${yr}_${mm} || echo "Some file is missing "
     rm -f  FINITO
     fixenkfid=`qsub ./fixenkf.sh `
     fixenkfans="R"
     while ( [ "${fixenkfans}" == "Q" ] || [ "${fixenkfans}" == "R" ] ); do
       fixenkfans=`qstat ${fixenkfid} 2>/dev/null | tail -n 1 | awk '{print $5}'`
       echo "waiting for fix EnKF-SST"
       sleep 15s
     done
     ./ensave forecast $ENSSIZE &
     wait
     mv  forecast_avg.nc ${WORKDIR}/RESULT/${yr}_${mm}/fix_analysis_avg.nc
     ans=`diff ${WORKDIR}/RESULT/${yr}_${mm}/fix_analysis_avg.nc ${WORKDIR}/RESULT/${yr}_${mm}/analysis_avg.nc`
     if [ -z "${ans}" ];             then
       echo "There has been no fix update, we quit!!" | mail -s "`date`: Missing fix update" earnestshen@gmail.com
       echo "Delete FINITO"
       rm -f FINITO
       exit 1;
     fi
     #Do some clean up
     rm -f  forecast???.nc
     rm -f observations.uf enkf.prm infile.data mask.nc
     echo 'Finished with Assim post-processing'
     date
  done
done # for years

###############################################################################
echo ${JobStartTime}
echo `date`" || "${JobName}
echo ${LinnBreaker}



