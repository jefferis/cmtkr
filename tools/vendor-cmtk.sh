#!/bin/bash
# vendor-cmtk.sh — copy needed CMTK sources into cmtkr/src/cmtk/
#
# Usage: tools/vendor-cmtk.sh /path/to/cmtk-master
#
# Run from the cmtkr package root directory.
# Requires a CMTK source checkout (e.g. extracted from cmtk-master.zip).

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 /path/to/cmtk-master" >&2
  exit 1
fi

CMTK_SRC="$1/core/libs"

if [ ! -d "$CMTK_SRC/Base" ]; then
  echo "Error: $CMTK_SRC/Base not found. Pass the cmtk-master root directory." >&2
  exit 1
fi

DEST=src/cmtk

# Clean previous vendor
rm -rf "$DEST"
mkdir -p "$DEST/Base" "$DEST/IO" "$DEST/System" "$DEST/Numerics"

# ------------------------------------------------------------------
# 1. Copy ALL headers and .txx template files
# ------------------------------------------------------------------
cp "$CMTK_SRC"/Base/*.h     "$DEST/Base/"
cp "$CMTK_SRC"/Base/*.txx   "$DEST/Base/"
cp "$CMTK_SRC"/IO/*.h       "$DEST/IO/"
cp "$CMTK_SRC"/IO/*.txx     "$DEST/IO/"
cp "$CMTK_SRC"/System/*.h   "$DEST/System/"
cp "$CMTK_SRC"/System/*.txx "$DEST/System/"
cp "$CMTK_SRC"/Numerics/*.h "$DEST/Numerics/"

# ------------------------------------------------------------------
# 2. Copy needed .cxx files
# ------------------------------------------------------------------

# Base (34)
BASE_CXX="cmtkXform cmtkXform_Inverse cmtkXformList cmtkXformListEntry
  cmtkAffineXform cmtkWarpXform cmtkSplineWarpXform
  cmtkSplineWarpXform_Inverse cmtkSplineWarpXform_Jacobian
  cmtkSplineWarpXform_Rigidity
  cmtkPolynomialXform cmtkTypes cmtkMatrix3x3 cmtkMatrix4x4
  cmtkCompatibilityMatrix4x4 cmtkVector cmtkBitVector
  cmtkMetaInformationObject
  cmtkAnatomicalOrientation cmtkAnatomicalOrientationBase
  cmtkAnatomicalOrientationPermutationMatrix
  cmtkDataGrid cmtkDataGrid_Crop
  cmtkUniformVolume cmtkUniformVolume_Crop
  cmtkUniformVolume_Differential cmtkUniformVolume_Resample
  cmtkUniformVolume_Space
  cmtkVolume cmtkTypedArray cmtkTypedArray_Statistics
  cmtkScalarImage cmtkHistogram
  cmtkLandmark cmtkLandmarkList cmtkLandmarkPair
  cmtkMathUtil_LinAlg cmtkVolumeGridToGridLookup"

for f in $BASE_CXX; do
  cp "$CMTK_SRC/Base/$f.cxx" "$DEST/Base/"
done

# IO (11)
IO_CXX="cmtkXformIO cmtkXformListIO cmtkClassStreamAffineXform
  cmtkClassStreamWarpXform cmtkClassStreamPolynomialXform
  cmtkTypedStream cmtkTypedStreamInput cmtkTypedStreamOutput
  cmtkTypedStreamStudylist cmtkFileFormat cmtkAffineXformITKIO"

for f in $IO_CXX; do
  cp "$CMTK_SRC/IO/$f.cxx" "$DEST/IO/"
done

# System (15 — includes threading for all platforms)
SYSTEM_CXX="cmtkConsole cmtkFileUtils cmtkMountPoints cmtkStrUtility
  cmtkMemory cmtkCompressedStream cmtkCompressedStreamFile
  cmtkCompressedStreamZlib cmtkCompressedStreamPipe
  cmtkCompressedStreamReaderBase cmtkThreads cmtkThreadPoolGCD
  cmtkSafeCounterGCD cmtkThreadPoolThreads cmtkProgress"

for f in $SYSTEM_CXX; do
  cp "$CMTK_SRC/System/$f.cxx" "$DEST/System/"
done

# Numerics (15 — AlgLib dependencies of MathUtil_LinAlg)
NUMERICS_CXX="ap blas rotations tdevd sblas reflections tridiagonal
  cholesky bidiagonal qr lq bdsvd sevd spddet svd"

for f in $NUMERICS_CXX; do
  cp "$CMTK_SRC/Numerics/$f.cxx" "$DEST/Numerics/"
done

# ------------------------------------------------------------------
# 3. Create ThreadSemaphore dispatcher
# ------------------------------------------------------------------
cat > "$DEST/System/cmtkThreadSemaphore.cxx" << 'EOFCXX'
/*
// Dispatcher for platform-specific ThreadSemaphore implementation.
// Includes the appropriate .txx based on platform defines.
*/

#include <cmtkconfig.h>
#include <System/cmtkThreadSemaphore.h>

#if defined(CMTK_USE_PTHREADS)
#  if defined(__APPLE__) || defined(__CYGWIN__)
#    include "cmtkThreadSemaphoreAppleIsRetarded.txx"
#  else
#    include "cmtkThreadSemaphorePOSIX.txx"
#  endif
#elif defined(_MSC_VER)
#  include "cmtkThreadSemaphoreWindows.txx"
#else
#  include "cmtkThreadSemaphoreNone.txx"
#endif
EOFCXX

# ------------------------------------------------------------------
# 4. Patch vendored code for R compliance
# ------------------------------------------------------------------
# R packages must not call exit(), printf(), fprintf(stderr,...),
# or use std::cout/cerr directly. Replace with R equivalents.

echo "Applying R compliance patches..."

# 4a. Remove mxml from MetaInformationObject.h
# (removes mxml.h include and all XML-related members/methods)
# See the patched file in version control for the exact changes.

# 4b. Silence Console globals (no std::cout/cerr in R packages)
sed -i.bak 's/Console StdErr( &std::cerr );/Console StdErr( NULL );/' "$DEST/System/cmtkConsole.cxx"
sed -i.bak 's/Console StdOut( &std::cout );/Console StdOut( NULL );/' "$DEST/System/cmtkConsole.cxx"

# 4c. Replace printf with Rprintf in cmtkMemory.cxx
sed -i.bak '/#include <limits.h>/a\
#include <R_ext/Print.h>' "$DEST/System/cmtkMemory.cxx"
sed -i.bak 's/    printf(/    Rprintf(/g' "$DEST/System/cmtkMemory.cxx"

# 4d. Replace fprintf(stderr,...) with REprintf in cmtkTypedArray.cxx
sed -i.bak '/#include <math.h>/a\
#include <R_ext/Print.h>' "$DEST/Base/cmtkTypedArray.cxx"
sed -i.bak 's/  fprintf( *stderr, */  REprintf( /g' "$DEST/Base/cmtkTypedArray.cxx"
sed -i.bak 's/  fprintf(stderr,/  REprintf(/g' "$DEST/Base/cmtkTypedArray.cxx"

# 4e. Replace fputs(stderr) with REprintf in cmtkTypedStream.cxx
sed -i.bak '/#include <limits.h>/a\
#include <R_ext/Print.h>' "$DEST/IO/cmtkTypedStream.cxx"
sed -i.bak '/fputs( buffer, stderr );/{N;s/fputs( buffer, stderr );\n  fputs( "\\n", stderr );/REprintf( "%s\\n", buffer );/;}' "$DEST/IO/cmtkTypedStream.cxx"

# 4f. Replace fprintf(stderr,...) with REprintf in cmtkCompressedStreamPipe.cxx
sed -i.bak '/#include <errno.h>/a\
#include <R_ext/Print.h>' "$DEST/System/cmtkCompressedStreamPipe.cxx"
sed -i.bak 's/    fprintf( stderr,/    REprintf(/g' "$DEST/System/cmtkCompressedStreamPipe.cxx"
# Remove perror call
sed -i.bak '/perror( "System message" );/d' "$DEST/System/cmtkCompressedStreamPipe.cxx"

# 4g. Replace std::cerr and fprintf(stderr) in cmtkThreads.cxx
sed -i.bak '/#include <algorithm>/a\
#include <R_ext/Print.h>' "$DEST/System/cmtkThreads.cxx"
sed -i.bak 's/      std::cerr << "INFO: number of threads.*$/      REprintf("INFO: number of threads set to %d according to environment variable CMTK_NUM_THREADS\\n", numThreads);/' "$DEST/System/cmtkThreads.cxx"
sed -i.bak 's/      std::cerr << "WARNING: environment variable.*$/      REprintf("WARNING: environment variable CMTK_NUM_THREADS is set but does not seem to contain a number larger than 0.\\n");/' "$DEST/System/cmtkThreads.cxx"
sed -i.bak 's/      fprintf( stderr,/      REprintf(/g' "$DEST/System/cmtkThreads.cxx"

# 4h. Replace exit() with Rf_error() in thread pool files
sed -i.bak '/#include <System\/cmtkConsole.h>/a\
#include <R_ext/Error.h>' "$DEST/System/cmtkThreadPoolGCD.cxx"
sed -i.bak '/StdErr << "ERROR: trying to run zero tasks.*/{N;s/.*StdErr.*\n.*exit( 1 );/    Rf_error("ERROR: trying to run zero tasks on thread pool. Did you forget to resize the parameter vector?");/;}' "$DEST/System/cmtkThreadPoolGCD.cxx"

sed -i.bak '/#include <System\/cmtkConsole.h>/a\
#include <R_ext/Error.h>' "$DEST/System/cmtkThreadPoolThreads.cxx"
sed -i.bak 's/	exit( 1 );/	Rf_error("Creation of pooled thread failed.");/g' "$DEST/System/cmtkThreadPoolThreads.cxx"

# 4i. Replace exit() in .txx template files
sed -i.bak '/#include <System\/cmtkConsole.h>/a\
#include <R_ext/Print.h>\
#include <R_ext/Error.h>' "$DEST/System/cmtkThreadParameterArray.txx"
sed -i.bak 's/	fprintf( stderr, "Creation of thread #%d failed\\.\\n", (int)threadIdx );/	Rf_error( "Creation of thread #%d failed.", (int)threadIdx );/g' "$DEST/System/cmtkThreadParameterArray.txx"
sed -i.bak 's/	fprintf( stderr, "Creation of thread #%d failed with status %d\\.\\n", (int)threadIdx, (int)status );/	Rf_error( "Creation of thread #%d failed with status %d.", (int)threadIdx, (int)status );/g' "$DEST/System/cmtkThreadParameterArray.txx"
sed -i.bak '/	exit( 1 );/d' "$DEST/System/cmtkThreadParameterArray.txx"

sed -i.bak '/#include <omp.h>/a\
#endif\
#include <R_ext/Error.h>\
#ifdef _OPENMP_DUMMY_RESTORE' "$DEST/System/cmtkThreadPoolThreads.txx"
# Simpler: just add include after the existing includes block
sed -i.bak 's|#include <System/cmtkConsole.h>|#include <System/cmtkConsole.h>\n#include <R_ext/Error.h>|' "$DEST/System/cmtkThreadPoolThreads.txx"
sed -i.bak '/StdErr << "ERROR: trying to run zero tasks.*/{N;s/.*StdErr.*\n.*exit( 1 );/    Rf_error("ERROR: trying to run zero tasks on thread pool. Did you forget to resize the parameter vector?");/;}' "$DEST/System/cmtkThreadPoolThreads.txx"

# Thread semaphore .txx files
sed -i.bak '/#include <stdlib.h>/a\
#include <R_ext/Error.h>' "$DEST/System/cmtkThreadSemaphorePOSIX.txx"
sed -i.bak 's/    std::cerr << "ERROR: sem_init.*$/    Rf_error( "ERROR: sem_init failed with errno=%d", errno );/;s/    std::cerr << "ERROR: sem_destroy.*$/    Rf_error( "ERROR: sem_destroy failed with errno=%d", errno );/;s/      std::cerr << "ERROR: sem_post.*$/      Rf_error( "ERROR: sem_post failed with errno=%d", errno );/;s/    std::cerr << "ERROR: sem_wait.*$/    Rf_error( "ERROR: sem_wait failed with errno=%d", errno );/' "$DEST/System/cmtkThreadSemaphorePOSIX.txx"
sed -i.bak '/    exit( 1 );/d' "$DEST/System/cmtkThreadSemaphorePOSIX.txx"

sed -i.bak '/#include <iostream>/a\
#include <R_ext/Error.h>' "$DEST/System/cmtkThreadSemaphoreWindows.txx"
sed -i.bak 's/    std::cerr << "CreateSemaphore error: " << GetLastError() << std::endl;/    Rf_error( "CreateSemaphore error: %lu", GetLastError() );/' "$DEST/System/cmtkThreadSemaphoreWindows.txx"
sed -i.bak '/    exit( 1 );/d' "$DEST/System/cmtkThreadSemaphoreWindows.txx"

# 4j. Wrap GCD files in #ifdef guards (compile to empty on non-Apple)
for f in cmtkThreadPoolGCD.cxx cmtkSafeCounterGCD.cxx; do
  if ! grep -q 'CMTK_USE_GCD' "$DEST/System/$f"; then
    sed -i.bak '/#include <cmtkconfig.h>/a\
#ifdef CMTK_USE_GCD' "$DEST/System/$f"
    echo '#endif // CMTK_USE_GCD' >> "$DEST/System/$f"
  fi
done

# 4k. Fix abs(unsigned) warning in cmtkTemplateArray.h
sed -i.bak 's/Data\[i\] = std::abs( Data\[i\] );/Data[i] = static_cast<T>( std::abs( static_cast<double>( Data[i] ) ) );/' "$DEST/Base/cmtkTemplateArray.h"

# 4l. Fix %ld format for long long in cmtkTypedStreamOutput.cxx
sed -i.bak 's/gzprintf( GzFile, "%ld ", array\[i\] );/gzprintf( GzFile, "%lld ", array[i] );/g' "$DEST/IO/cmtkTypedStreamOutput.cxx"
sed -i.bak 's/fprintf( File, "%ld ", array\[i\] );/fprintf( File, "%lld ", array[i] );/g' "$DEST/IO/cmtkTypedStreamOutput.cxx"

# 4m. Fix exit() in header files
sed -i.bak '/#include <Base\/cmtkTypes.h>/a\
#include <stdexcept>' "$DEST/Base/cmtkFunctional.h"
sed -i.bak '/StdErr << "ERROR: Functional::SetParamVector.*/{N;s/.*StdErr.*\n.*exit( 1 );/    throw std::logic_error( "Functional::SetParamVector() was called but not implemented" );/;}' "$DEST/Base/cmtkFunctional.h"
sed -i.bak '/StdErr << "ERROR: Functional::GetParamVector.*/{N;s/.*StdErr.*\n.*exit( 1 );/    throw std::logic_error( "Functional::GetParamVector() was called but not implemented" );/;}' "$DEST/Base/cmtkFunctional.h"

# Remove DEBUG-only exit() in interpolator headers
sed -i.bak '/#ifdef DEBUG/{N;N;N;/std::cerr.*exit/{N;s/#ifdef DEBUG\n.*std::cerr.*\n.*exit.*\n#endif//;}}' "$DEST/Base/cmtkNearestNeighborInterpolator.h"
sed -i.bak '/#ifdef DEBUG/{N;N;N;/std::cerr.*exit/{N;s/#ifdef DEBUG\n.*std::cerr.*\n.*exit.*\n#endif//;}}' "$DEST/Base/cmtkLinearInterpolator.h"

# 4n. Fix C++20 template-id constructor (Matrix3D<T> -> Matrix3D)
sed -i.bak 's/Matrix3D<T>$/Matrix3D/' "$DEST/Base/cmtkMatrix.h"

# 4o. Fix futimes() not available on Windows (MinGW)
sed -i.bak 's/#ifndef _MSC_VER/#if !defined(_MSC_VER) \&\& !defined(_WIN32)/' "$DEST/IO/cmtkTypedStreamOutput.cxx"

# 4p. Fix unused getcwd return value warning (GCC ignores (void) cast)
sed -i.bak 's/    getcwd( absPath, PATH_MAX );/    if ( getcwd( absPath, PATH_MAX ) == NULL ) absPath[0] = 0;/' "$DEST/System/cmtkFileUtils.cxx"

# 4q. Fix stringop-overflow warning in FixedSquareMatrix assignment
# Replace memcpy with element-wise copy to avoid GCC false positive
sed -i.bak '/memcpy( this->m_Matrix, other.m_Matrix, sizeof( this->m_Matrix ) );/{
s/.*/  for ( size_t i = 0; i < NDIM; ++i )\
    for ( size_t j = 0; j < NDIM; ++j )\
      this->m_Matrix[i][j] = other.m_Matrix[i][j];/
}' "$DEST/Base/cmtkFixedSquareMatrix.txx"

# 4r. Fix mkdir() for MinGW in cmtkFileUtils.cxx
# On MinGW, mkdir() takes 1 arg (no permissions). Use _WIN32 guard instead
# of _MSC_VER for mkdir calls. Keep _MSC_VER for includes and GetFullPathName.
sed -i.bak 's/_mkdir( filename.c_str() )/mkdir( filename.c_str() )/' "$DEST/System/cmtkFileUtils.cxx"
sed -i.bak 's/_mkdir( prefix )/mkdir( prefix )/' "$DEST/System/cmtkFileUtils.cxx"
# Use awk to change _MSC_VER to _WIN32 in RecursiveMkDir/RecursiveMkPrefixDir
# but not in the includes block or GetAbsolutePath
awk '/RecursiveMkDir/{ in_mk=1 } /GetAbsolutePath/{ in_mk=0 } in_mk && /#ifdef _MSC_VER/{ sub(/_MSC_VER/, "_WIN32") } { print }' \
  "$DEST/System/cmtkFileUtils.cxx" > "$DEST/System/cmtkFileUtils.cxx.tmp" && \
  mv "$DEST/System/cmtkFileUtils.cxx.tmp" "$DEST/System/cmtkFileUtils.cxx"

# 4s. Fix sysconf/_SC_NPROCESSORS_ONLN not available on MinGW
# Change _MSC_VER to _WIN32 in GetMaxThreads and GetNumberOfProcessors
# so MinGW uses Windows API instead of sysconf. Add windows.h for MinGW.
sed -i.bak '/#include <errno.h>/a\
#endif\
\
#if defined(_WIN32) \&\& !defined(_MSC_VER)\
#  include <windows.h>' "$DEST/System/cmtkThreads.cxx"
# Use awk to change _MSC_VER to _WIN32 in GetMaxThreads and GetNumberOfProcessors
awk '/GetMaxThreads|GetNumberOfProcessors/{ in_fn=1; fn_braces=0 }
     in_fn && /{/{ fn_braces++ }
     in_fn && /}/{ fn_braces--; if(fn_braces<=0) in_fn=0 }
     in_fn && /#ifdef _MSC_VER/{ sub(/_MSC_VER/, "_WIN32") }
     { print }' \
  "$DEST/System/cmtkThreads.cxx" > "$DEST/System/cmtkThreads.cxx.tmp" && \
  mv "$DEST/System/cmtkThreads.cxx.tmp" "$DEST/System/cmtkThreads.cxx"

# Clean up .bak files from sed
find "$DEST" -name '*.bak' -delete

echo "Vendored $(find "$DEST" -name '*.h' | wc -l | tr -d ' ') headers and $(find "$DEST" -name '*.cxx' | wc -l | tr -d ' ') source files."
echo ""
echo "IMPORTANT: After running this script, manually verify the patch to"
echo "  src/cmtk/Base/cmtkMetaInformationObject.h"
echo "  (remove mxml.h include and XML member functions/data)"
echo ""
echo "Then also copy the static cmtkconfig.h into src/cmtk/cmtkconfig.h"
