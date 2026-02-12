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

# System (14)
SYSTEM_CXX="cmtkConsole cmtkFileUtils cmtkMountPoints cmtkStrUtility
  cmtkMemory cmtkCompressedStream cmtkCompressedStreamFile
  cmtkCompressedStreamZlib cmtkCompressedStreamPipe
  cmtkCompressedStreamReaderBase cmtkThreads cmtkThreadPoolGCD
  cmtkSafeCounterGCD cmtkProgress"

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
# 3. Patch: remove mxml from MetaInformationObject.h
# ------------------------------------------------------------------
# The patch removes the mxml.h include and all XML-related members/methods,
# since we only need the key-value metadata support for point transforms.
# See the patched file in version control for the exact changes.

echo "Vendored $(find "$DEST" -name '*.h' | wc -l | tr -d ' ') headers and $(find "$DEST" -name '*.cxx' | wc -l | tr -d ' ') source files."
echo ""
echo "IMPORTANT: After running this script, manually verify the patch to"
echo "  src/cmtk/Base/cmtkMetaInformationObject.h"
echo "  (remove mxml.h include and XML member functions/data)"
echo ""
echo "Then also copy the static cmtkconfig.h into src/cmtk/cmtkconfig.h"
