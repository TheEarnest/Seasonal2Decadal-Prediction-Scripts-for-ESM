#!/usr/bin/env python
#--------------------------------------------------------------------
# load module
#
from datetime import date
from calendar import isleap
import sys
#--------------------------------------------------------------------

# from Scientific.IO.NetCDF import NetCDFFile as NCDataset  # No Scientific on Hexagon
#--------------------------------------------------------------------
# define parameters
y1 = int(sys.argv[1])  # 
m1 = int(sys.argv[2]) # 
d1 = int(sys.argv[3])

y2 = int(sys.argv[4])  #
m2 = int(sys.argv[5]) #
d2 = int(sys.argv[6])

if isleap(y1) or isleap(y2) :
  delta = date(y2,m2,d2) - date(y1,m1,d1+1)
else :
  delta = date(y2,m2,d2) - date(y1,m1,d1)

print delta.days

#--------------------------------------------------------------------
