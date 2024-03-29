PATH_GLOBAL="data/jags/global-scale"
PATH_LOCAL="data/jags/local-scale"

CSV="\\.csv$"
RDS="\\.rds$"
ASC="\\.asc$"
TIF="\\.tiff?$"

ELEV_SPANS=c(1500, 2000, 2500)
ELEV_SPAN_DEFAULT=ELEV_SPANS[3]

EXCLS=c(0, 250, 500)
EXCL_DEFAULT=EXCLS[2]

CI=c(.8, .95, .99)
CI_DEFAULT=CI[2]

N_DRAWS=600
SINGLETON_THR=25
ELEV_BIN_WIDTH=100

JAGS_ITER=50000
JAGS_THIN=5
JAGS_CHAINS=3
JAGS_BURN_IN=20000
JAGS_EFF_SIZE=3000

VERSION_R="4.0.2"
VERSION_PALEOVIEW="1.5.1"
VERSION_COORDINATE_CLEANER=packageVersion("CoordinateCleaner")
VERSION_R2JAGS=packageVersion("R2jags")
VERSION_LOO=packageVersion("loo")
