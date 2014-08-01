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
platforms. The main problem that I encountered on mac so far is loading CMTK's
dynamic libraries. I ended up doing:

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
reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtk')

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
