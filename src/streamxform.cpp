#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>
#include <Base/cmtkXform.h>
#include <Base/cmtkXformList.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkXformListIO.h>

namespace {

void xformlist_finalizer(SEXP ptr) {
  if (TYPEOF(ptr) != EXTPTRSXP) {
    return;
  }

  void* addr = R_ExternalPtrAddr(ptr);
  if (addr == NULL) {
    return;
  }

  cmtk::XformList* xformList = static_cast<cmtk::XformList*>(addr);
  delete xformList;
  R_ClearExternalPtr(ptr);
}

cmtk::XformList* checked_xformlist_ptr(SEXP ptr) {
  if (TYPEOF(ptr) != EXTPTRSXP) {
    stop("xform_ptr must be an external pointer");
  }

  void* addr = R_ExternalPtrAddr(ptr);
  if (addr == NULL) {
    stop("xform_ptr is NULL (the object may have been freed)");
  }

  return static_cast<cmtk::XformList*>(addr);
}

NumericMatrix apply_xformlist(NumericMatrix points, const cmtk::XformList& xformList) {
  const int nrow = points.nrow();
  const int ncol = points.ncol();
  NumericMatrix pointst(nrow, ncol);

  cmtk::Xform::SpaceVectorType xyz;

  for (int j = 0; j < nrow; j++) {
    for (int i = 0; i < ncol; i++) {
      xyz[i] = points(j, i);
    }
    const bool valid = xformList.ApplyInPlace(xyz);
    for (int i = 0; i < ncol; i++) {
      if (valid) {
        pointst(j, i) = xyz[i];
      } else {
        pointst(j, i) = NA_REAL;
      }
    }
  }

  return pointst;
}

} // namespace

//' transform 3D points using one or more CMTK registrations
//'
//' @details To transform points from sample to reference space, you will need
//'   to use the inverse transformation. This can be achieved by preceding the
//'   registration with a \verb{--inverse} flag. When multiple registrations are
//'   being used the are ordered from sample to reference brain.
//' @param points an Nx3 matrix of 3D points
//' @param reglist A character vector specifying registrations. See details.
//' @param inversionTolerance the precision of the numerical inversion when
//'   transforming in the inverse direction.
//' @param affineonly Whether to apply only the affine portion of transforms
//'   default \code{FALSE}.
//' @export
//' @examples
//' \dontrun{
//' m=matrix(rnorm(30,mean = 50), ncol=3)
//' reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')
//' # from reference to sample
//' streamxform(m, reg)
//'
//' # from sample to reference
//' streamxform(m, c("--inverse", reg))
//'
//' # concatenating 3 registrations to map S -> B1 -> B2 -> T
//' # the first two registrations are inverted, the last is not.
//' streamxform(m, c("--inverse", StoB1, "--inverse", B1toB2, TtoB2))
//' }
// [[Rcpp::export]]
NumericMatrix streamxform(NumericMatrix points, CharacterVector reglist,
  double inversionTolerance=1e-8, bool affineonly = false) {
  std::vector<std::string> regvec = Rcpp::as<std::vector<std::string> >(reglist);
  cmtk::XformList xformList = cmtk::XformListIO::MakeFromStringList(regvec);
  xformList.SetEpsilon( cmtk::Types::Coordinate(inversionTolerance) );

  if (affineonly) {
    xformList = xformList.MakeAllAffine();
  }

  return apply_xformlist(points, xformList);
}

// [[Rcpp::export]]
SEXP xformlist_load(CharacterVector reglist, double inversionTolerance = 1e-8,
                    bool affineonly = false) {
  std::vector<std::string> regvec = Rcpp::as<std::vector<std::string> >(reglist);
  cmtk::XformList* xformList = new cmtk::XformList(cmtk::XformListIO::MakeFromStringList(regvec));
  xformList->SetEpsilon(cmtk::Types::Coordinate(inversionTolerance));

  if (affineonly) {
    *xformList = xformList->MakeAllAffine();
  }

  SEXP ptr = PROTECT(R_MakeExternalPtr(xformList, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, xformlist_finalizer, static_cast<Rboolean>(TRUE));
  UNPROTECT(1);
  return ptr;
}

// [[Rcpp::export]]
NumericMatrix streamxform_ptr(NumericMatrix points, SEXP xform_ptr) {
  cmtk::XformList* xformList = checked_xformlist_ptr(xform_ptr);
  return apply_xformlist(points, *xformList);
}
