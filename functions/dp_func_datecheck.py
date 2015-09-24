
#--------------------------------------------------------------------
# load module
#
from datetime import date
from dateutil.relativedelta import relativedelta
from calendar import isleap
import sys
#--------------------------------------------------------------------

# from Scientific.IO.NetCDF import NetCDFFile as NCDataset  # No Scientific on Hexagon
#--------------------------------------------------------------------
# define parameters
year = int(sys.argv[1])  # 
month = int(sys.argv[2]) # 
day = int(sys.argv[3])
dateBase = sys.argv[4]
dateinterval = int(sys.argv[5])

if dateBase == "months" :
  Ndate = date(year,month,day) + relativedelta(months=+dateinterval)
elif dateBase == "days" :
  Ndate = date(year,month,day) + relativedelta(days=+dateinterval)

if (month <= 2) and (Ndate.month > 2):
  if isleap(Ndate.year) and (dateBase ==  "days"):
    Ndate = Ndate + relativedelta(days=+1)

print Ndate

#--------------------------------------------------------------------
