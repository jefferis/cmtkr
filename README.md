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

### Linking issues

Before any public release, it will be essential to figure out how to get 
(dynamic) linking against the binary CMTK distribution. On MacOSX the default is
dynamic linking against .dylib files. However these must be located at runtime.

CMTK places static libraries in /opt/local/lib/cmtk by default. It does not ship
with dynamic libraries. When these are shipped they are placed in the same 
location. However they do not have a full path e.g.

```
$ otool -L /opt/local/lib/cmtk/libcmtkBase.dylib 
/opt/local/lib/cmtk/libcmtkBase.dylib:
  libcmtkBase.dylib (compatibility version 0.0.0, current version 0.0.0)
	libcmtkSystem.dylib (compatibility version 0.0.0, current version 0.0.0)
	libcmtkNumerics.dylib (compatibility version 0.0.0, current version 0.0.0)
	/usr/lib/libbz2.1.0.dylib (compatibility version 1.0.0, current version 1.0.5)
	/usr/lib/libz.1.dylib (compatibility version 1.0.0, current version 1.2.5)
	libcmtkMxml.dylib (compatibility version 0.0.0, current version 0.0.0)
	/usr/lib/libstdc++.6.dylib (compatibility version 7.0.0, current version 56.0.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 169.3.0)
```

unlike every other library on my machine which has explicit paths encoded. There
do seem to be fancier approaches (e.g. http://www.kitware.com/blog/home/post/510)
but something like this (from teem) seems to work:

```
  BUILD_WITH_INSTALL_RPATH OFF
  INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib
  INSTALL_NAME_DIR ${CMAKE_INSTALL_PREFIX}/lib
```
