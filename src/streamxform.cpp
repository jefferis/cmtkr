#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>
#include <Base/cmtkXform.h>
#include <Base/cmtkXformList.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkXformListIO.h>
#include <IO/cmtkVolumeIO.h>

//' streamxform a set of points
//' @param points an Nx3 set of 3D points
//' @export
// [[Rcpp::export]]
NumericMatrix streamxform(NumericMatrix points, CharacterVector reglist) {
  cmtk::XformList xformList = cmtk::XformListIO::MakeFromStringList(
    Rcpp::as<std::vector<std::string> >(reglist) );

  int nrow = points.nrow();
  int ncol = points.ncol();
  NumericMatrix pointst(nrow, ncol);

  cmtk::Xform::SpaceVectorType xyz;
  cmtk::Types::Coordinate inversionTolerance = 1e-8;
  xformList.SetEpsilon( inversionTolerance );

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
