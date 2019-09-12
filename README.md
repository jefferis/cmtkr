# cmtkr
An R package to wrap the [CMTK](http://www.nitrc.org/projects/cmtk/), the
Computational Morphometry Toolkit. The goals is to enable direct calls to the
CMTK library, bypassing command line tools, potentially resulting in order of
magnitude speedups.

## Installation
Currently there isn't a released version on [CRAN](http://cran.r-project.org/) 
but you can install using devtools.

```r
if(!require("devtools")) install.packages("devtools")
devtools::install_github("jefferis/cmtkr")
```

Besides the R package itself, you will need an installation of CMTK with shared
libraries built. So far, I have only achieved this by compiling from source on
Mac OSX, although the procedure should be almost identical on other unix 
platforms. When using building CMTK with static libraries (the default)
everything behaved well, although there may be issues depending on which 
additional libraries (e.g. NrrdIO, fftw etc you choose to build with CMTK).

I previously encountered problems with loading CMTK's dynamic libraries on Mac.
I ended up doing:

```sh
cd /usr/local/lib
ln -s cmtk/*.dylib .
```
Adding `/usr/local/lib/cmtk` to `LD_LIBRARY_PATH` would be the more general unix
way of doing this. I do not know if this can be done in a package's .onLoad or 
if there is an alternative strategy.

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
* include the full CMTK library within the package (but this would introduce
  a cmake dependency for compilation)
* figure out how to use the headers and libraries supplied with the default
  CMTK binary installation (these are static libraries).

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
