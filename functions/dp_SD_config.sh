#! /bin/ksh
# 2015/01/15 by Mao-Lin Shen

Ensembles='1 2 3 4 5'
CaseConfig=ME
CASEDIR=NorCPM_ME
if [ "${CaseConfig}" == "ME" ] ; then
  GRIDPATH=/work/shared/noresm/inputdata/ocn/micom/gx1v6/20101119/grid.nc
  COMPSET=N20TREXTAERCN
  RES=f19_g16 
elif [ "${CaseConfig}" == "F19tn21" ] ; then
  GRIDPATH=/work/shared/noresm/inputdata/ocn/micom/tnx2v1/20130206/grid.nc
  COMPSET=N20TREXT
  RES=f19_tn21 
else
  COMPSET=N20TREXT
  RES=f19_tn21
fi
VERSION=${CASEDIR}'_mem'


PRODUCERLIST='HADISST2'
OBSLIST="SST"
ANOMALYASSIM=0;  MONTHLY_ANOM='1'; SUPERLAYER='1'

#FOLLOWING is related to the starting option
ens_start=1 #1 means we start hybrid from an ensemble run
ens_casename=noresm1_ME_hist_s01_mem
ens_start_date=1991-04-15-00000
branched_ens_date=1991-01-01-00000
hist_start=0 #1 means we start hybrid from anstorical run
#first member use year 0001 and then all member use year+5 
#TODO Not Finished
hist_start_date=1500
hist_freq_date=10

the_start_date=1991-04-15-00000
short_start_date=`echo $the_start_date | cut -c1-10`
STARTMONTH=`echo $the_start_date | cut -c6-7`



# parameters for DA only 
OBSTYPE='SST'
PRODUCER='HADISST2'
REF_PERIOD='1980-2000' # for calculating anomalies


