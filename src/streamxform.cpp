#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>
#include <Base/cmtkXform.h>
#include <Base/cmtkXformList.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkXformListIO.h>

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
//' @return an Nx3 matrix of 3D points after transformation
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

  int nrow = points.nrow();
  int ncol = points.ncol();
  NumericMatrix pointst(nrow, ncol);

  cmtk::Xform::SpaceVectorType xyz;

  xformList.SetEpsilon( cmtk::Types::Coordinate(inversionTolerance) );

  if (affineonly) {
    xformList = xformList.MakeAllAffine();
  }

  for (int j = 0; j < nrow; j++) {
    for (int i = 0; i < ncol; i++) {
      xyz[i]=points(j,i);
    }
    const bool valid = xformList.ApplyInPlace( xyz );
    for (int i = 0; i < ncol; i++) {
      if(valid){
        pointst(j,i)=xyz[i];
      } else {
        pointst(j,i)=NA_REAL;
      }
    }
  }
  return pointst;
}
