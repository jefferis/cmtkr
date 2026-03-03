# cmtkr
  <!-- badges: start -->
  [![R-CMD-check](https://github.com/jefferis/cmtkr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jefferis/cmtkr/actions/workflows/R-CMD-check.yaml)
  <!-- badges: end -->

An R package to wrap [CMTK](https://www.nitrc.org/projects/cmtk/), the
Computational Morphometry Toolkit. The goal is to enable direct calls to the
CMTK library, bypassing command line tools, potentially resulting in order of
magnitude speedups for small jobs. For the end user, the greater impact may be 
to ensure that precompiled binaries are available via CRAN, avoiding 
installation of the cmtk library.

## Installation
Currently there isn't a released version on [CRAN](https://cran.r-project.org/)
but you can install using remotes.

```r
if(!require("remotes")) install.packages("remotes")
remotes::install_github("jefferis/cmtkr")
```

## Example

I have observed an approximately 100x speedup for transformations using the
cmtkr::streamxform function rather than the streamxform command line tool in the
*forward* direction. Inversion of the registration is however rather costly, so
the speedup then becomes a factor of less than 2 with the default parameters. 

```r
library(cmtkr)
library(nat)
library(microbenchmark)
m=matrix(rnorm(30000,mean = 50), ncol=3)
reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')

# cross check native vs command line tool
stopifnot(all.equal(streamxform(m, reg), xform(m, reg, direction='forward')))

# speed test
microbenchmark(streamxform(m, reg))
# Unit: milliseconds
#                 expr      min       lq   median       uq      max neval
#  streamxform(m, reg) 3.526031 3.532033 3.573981 3.644109 15.35925   100

microbenchmark(xform(m, reg, direction='forward'))
# Unit: milliseconds
#                                  expr      min       lq   median       uq      max neval
#  xform(m, reg, direction = "forward") 275.1514 278.3939 281.0234 283.2695 329.0713   100

microbenchmark(xform(m, reg, direction='inverse'), times = 10)
# Unit: milliseconds
#                                  expr      min       lq   median       uq      max neval
#  xform(m, reg, direction = "inverse") 660.6582 663.5988 664.4205 669.2614 675.8603    10

microbenchmark(streamxform(m, c("--inverse", reg)), times=10)
# Unit: milliseconds
#                                 expr     min       lq   median       uq     max neval
#  streamxform(m, c("--inverse", reg)) 386.935 388.4769 390.9554 393.2645 406.053    10
```

## Future plans

* teach the nat package to use this an alternative to nat::xformpoints.cmtkreg,
  the method called by xform when transforming objects based on 3D points.
* support persistent objects to reference in memory registrations to speed up 
  repeated application of the same registration.
* include a larger subset of the CMTK library within the package with some 
  additional entry points.
