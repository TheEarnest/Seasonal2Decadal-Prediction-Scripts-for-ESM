#Script called by main.sh, it links the corresponding restart file to the ANALYSIS forlder with name forecastxxx.nc 
#It also make a copy of forecastxxx.nc to analysisxxx.nc

set -ex 

year=$1
month=$2
mm=`echo 0$month | tail -3c`
yr=`echo 000$year | tail -5c`

cd ${WORKDIR}/ANALYSIS/

for (( proc = 1; proc <= ${ENSSIZE}; ++proc )) ; do
  mem=`echo 0$proc | tail -3c`
  mem3=`echo 00$proc | tail -4c`
  Rdate=${yr}-${mm}-15-00000
  tempf=`ls ${WORKDIR}/${REST_CaseName}${mem}/rest/${Rdate}/*.micom.r.${Rdate}.nc`
  Fprefix=`echo ${tempf} | awk -F "/" '{print $NF}' | awk -F ".micom.r." '{print $1}'`
  filename=${WORKDIR}/${REST_CaseName}${mem}/rest/${Rdate}/${Fprefix}.micom.r.${Rdate}.nc
  if [ ! -f ${filename} ]; then
    echo "The file  ${filename} is missing !! we quit"
  else
    ln -sf ${filename}  forecast${mem3}.nc
		fi
done


