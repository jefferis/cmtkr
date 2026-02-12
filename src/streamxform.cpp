#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>
#include <Base/cmtkXform.h>
#include <Base/cmtkXformList.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkXformListIO.h>
#include <IO/cmtkFileFormat.h>
#include <System/cmtkCompressedStream.h>

#include <sys/stat.h>

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

  // Debug: trace registration paths and filesystem state
  for (size_t i = 0; i < regvec.size(); i++) {
    Rcpp::Rcerr << "streamxform: reglist[" << i << "] = \"" << regvec[i] << "\"" << std::endl;
    if (regvec[i] != "--inverse" && regvec[i] != "-i") {
      struct stat buf;
      int sr = stat(regvec[i].c_str(), &buf);
      Rcpp::Rcerr << "  stat() = " << sr << ", mode = 0x" << std::hex << buf.st_mode << std::dec << std::endl;
      if (sr == 0) {
        if (buf.st_mode & S_IFDIR) Rcpp::Rcerr << "  -> is directory" << std::endl;
        if (buf.st_mode & S_IFREG) Rcpp::Rcerr << "  -> is regular file" << std::endl;
      }
      // Check CompressedStream::Stat
      cmtk::CompressedStream::StatType cbuf;
      int csr = cmtk::CompressedStream::Stat(regvec[i], &cbuf);
      Rcpp::Rcerr << "  CompressedStream::Stat() = " << csr << std::endl;
      // Check FileFormat::Identify
      cmtk::FileFormatID fmt = cmtk::FileFormat::Identify(regvec[i]);
      Rcpp::Rcerr << "  FileFormat::Identify() = " << (int)fmt << std::endl;
    }
  }

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
