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
  return points;
}
