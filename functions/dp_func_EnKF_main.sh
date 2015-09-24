#! /bin/bash
source ${NorCPM_config}
set -e

if [ ! -d ${WORKDIR}/ANALYSIS/ ] ; then
      mkdir -p ${WORKDIR}/ANALYSIS  || { echo "Could not create ANALYSIS dir" ; exit 1 ; }
fi
FIRST_INTERGRATION=1
for year in `seq ${STARTYEAR} ${ENDYEAR}`
do
 for month in `seq 1 12`
 do
    if [ $month -ge $STARTMONTH ]
    then
    STARTMONTH=0
    mm=`echo 0$month | tail -3c`
    yr=`echo 000$year | tail -5c`
    yr_assim=`echo 000$year | tail -5c`
    if (( ${SKIPASSIM} ))
       then
       echo 'model is at:' $year $month
       echo 'observation is at:' $yr_assim $month
       cd ${WORKDIR}/ANALYSIS/
       cp -f ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/SST_ens_${yr_assim}_${mm}.nc  .  || { echo "${WORKDIR}/OBS/${OBSTYPE}/${PRODUCER}/SST_ens_${yr_assim}_${mm}.nc, we quit" ; exit 1 ; }
       ln -sf ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/SST_avg_${mm}.nc mean_obs.nc || { echo "Error ${WORKSHARED}/Obs/${OBSTYPE}/${PRODUCER}/Anomaly/SST_avg_${mm}.nc missing, we quit" ; exit 1 ; }
       ln -sf ${WORKSHARED}/Input/NorESM/${CASEDIR}_${PRODUCER}_anom/ave-${mm}.nc mean_mod.nc || { echo "Error ${WORKSHARED}/Input/NorESM/${CASEDIR}_${PRODUCER}_anom/ave-${mm}.nc  missing, we quit" ; exit 1 ; }
       cat ${WORKSHARED}/Input/EnKF/infile.data.${OBSTYPE}.${PRODUCER} | sed  "s/yyyy/${yr_assim}/" | sed  "s/mm/${mm}/" > infile.data
       ln -sf  $GRIDPATH .
       ${HOMEDIR}/Script/Link_forecast.sh ${yr} ${month}
       ${HOMEDIR}/bin/prep_obs_ff 
       cp -f ${HOMEDIR}/bin/EnKF_ff ./EnKF
       cp -f ${HOMEDIR}/bin/ensave .
       cat ${WORKSHARED}/Script/pbs_enkf.sh_mal | sed  "s/NENS/${ENSSIZE}/" | sed  "s/nnXXXXk/${CPUACCOUNT}/"  > pbs_enkf.sh
       chmod 755 pbs_enkf.sh
       cp  -f ${WORKSHARED}/Input/EnKF/analysisfields.in .
       cat ${WORKSHARED}/Input/EnKF/enkf.prm_mal | sed  "s/XXX/${RFACTOR}/" > enkf.prm
       sed -i s/"enssize =".*/"enssize = "${ENSSIZE}/g enkf.prm
       #launch job and wait it finishes
       jobid=`qsub -v WORKDIR pbs_enkf.sh`
       finished=0
       while (( ! finished ))
       do
        finished=1
         answer=`qstat $jobid 2>/dev/null | tail -1 | awk '{print $5}'`
         if [ -z "${answer}" -o "${answer}" == "C" ]
         then
             answer=
             echo -n " Noresm assim job finished"
         else
             finished=0
             sleep 90
         fi
       done
       cd ${WORKDIR}/ANALYSIS
       ans=`diff forecast001.nc analysis001.nc | awk -F " " '{print $2}'`
       if [ "${ans}" == "" ] 
       then
             echo "There has been no update, we quit!!"
             exit 1
       fi
       cat ${WORKSHARED}/Input/EnKF/fixenkf.sh_mal | sed  "s/NENS/${ENSSIZE}/g"  > fixenkf.sh
       chmod 755 fixenkf.sh
       cp -f ${HOMEDIR}/bin/micom_serial_init .
       cp -f ${HOMEDIR}/bin/launcher${ENSSIZE} launcher
       ${HOMEDIR}/Script/Post_process_parallel.sh ${yr} ${month} ${ENSSIZE}
       if [ ! -f "FINITO" ] 
       then
         echo "Something went wrong in parallel postprocessing!! quit"
         exit
       fi

       (( RFACTOR = RFACTOR - 2 ))
       if [ $RFACTOR -lt 1 ] 
       then
          RFACTOR=1
       fi
    fi
    SKIPASSIM=1
    if (( ${SKIPPROP} ))
       then
       echo 'Integrate NorESM for a month'
       cd ${HOMEDIR}/cases/
       for (( proc = 1; proc <= $nbbatch; ++proc ))
       do
          jobid[${proc}]=`qsub ${CASEDIR}_pak${proc}.${machine}.run`
       done
       finished=0
       while (( ! finished ))
       do
         finished=1
         for (( proc = 1; proc <= $nbbatch; ++proc ))
         do
            if [ -z "${jobid[$proc]}" ]
            then
              continue
            fi
            answer=`qstat ${jobid[$proc]} 2>/dev/null | tail -1 | awk '{print $5}'`
            if [ -z "${answer}" -o "${answer}" == "C" ]
            then
                jobid[$proc]=
                echo -n " Noresm job finished for batch " $proc
            else
                finished=0
                sleep 60
                break
            fi
         done
       done
       if [ $month -eq 12 ]
       then
          let years=year+1
          ys=`echo 000$years | tail -5c`
          ms=01
       else
          ys=$yr
          let tmp=month+1
          ms=`echo 0$tmp | tail -3c`
       fi

       for (( proc = 1; proc <= ${ENSSIZE}; ++proc ))
       do
          mem=`echo 0$proc | tail -3c`
          cd ${WORKDIR}/${VERSION}${mem}/run/
          if [ ! -f "${VERSION}${mem}.micom.r.${ys}-${ms}-15-00000.nc" ] 
          then
             echo "The file  ${VERSION}${mem}.micom.r.${ys}-${ms}-15-00000.nc is missing !! we quit"
             exit
          fi
       done
       echo 'All jobs completed'
       mv ${HOMEDIR}/cases/NorCPM_pak* ${WORKDIR}/Log/ || echo "No old log files left......."

   fi
   SKIPPROP=1
   if [ $FIRST_INTERGRATION -a $hybrid_run ] ;then
      for i in `seq 01 ${ENSSIZE}`
      do
          mem=`echo 0$i | tail -3c`
          cd ${HOMEDIR}/cases/${VERSION}${mem}/
          xmlchange -file env_run.xml -id CONTINUE_RUN -val TRUE
      done
      FIRST_INTERGRATION=0
   fi
 fi
 done
done
echo " done"
