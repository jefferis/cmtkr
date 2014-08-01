#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>
#include <Base/cmtkXform.h>
#include <Base/cmtkXformList.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkXformListIO.h>
#include <IO/cmtkVolumeIO.h>

// [[Rcpp::export]]
NumericMatrix streamxform(NumericMatrix points, CharacterVector registration) {

  return points;
}
