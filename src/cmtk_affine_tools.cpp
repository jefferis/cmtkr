#include <Rcpp.h>

using namespace Rcpp;

#include <cmtkconfig.h>

#include <Base/cmtkAffineXform.h>
#include <IO/cmtkXformIO.h>
#include <IO/cmtkClassStreamOutput.h>
#include <IO/cmtkClassStreamAffineXform.h>

namespace {

void check_square_4x4(const NumericMatrix& m) {
  if (m.nrow() != 4 || m.ncol() != 4) {
    stop("`m` must be a 4x4 homogeneous affine matrix.");
  }
}

void transpose4x4(cmtk::Types::Coordinate (&matrix)[4][4]) {
  for (int row = 0; row < 4; ++row) {
    for (int col = 0; col < row; ++col) {
      const cmtk::Types::Coordinate tmp = matrix[col][row];
      matrix[col][row] = matrix[row][col];
      matrix[row][col] = tmp;
    }
  }
}

NumericMatrix affine_matrix_to_r(const cmtk::AffineXform& affine, const bool transpose, const bool matrix3x3) {
  const int n = matrix3x3 ? 3 : 4;
  NumericMatrix out(n, n);

  for (int j = 0; j < n; ++j) {
    for (int i = 0; i < n; ++i) {
      if (transpose) {
        out(j, i) = affine.Matrix[i][j];
      } else {
        out(j, i) = affine.Matrix[j][i];
      }
    }
  }

  return out;
}

} // namespace

// [[Rcpp::export]]
NumericMatrix cmtk_dof2mat_path(std::string reg, bool transpose = true, bool matrix3x3 = false) {
  cmtk::Xform::SmartPtr xform = cmtk::XformIO::Read(reg);
  cmtk::AffineXform::SmartPtr affineXform = cmtk::AffineXform::SmartPtr::DynamicCastFrom(xform);

  if (!affineXform) {
    stop("Registration is not affine or could not be read: `%s`", reg);
  }

  return affine_matrix_to_r(*affineXform, transpose, matrix3x3);
}

// [[Rcpp::export]]
NumericMatrix cmtk_dof2mat_params(NumericVector params, bool transpose = true, bool matrix3x3 = false) {
  if (params.size() != 15) {
    stop("`params` must have length 15.");
  }

  cmtk::Types::Coordinate raw[15];
  for (int i = 0; i < 15; ++i) {
    raw[i] = params[i];
  }

  cmtk::AffineXform affineXform(raw);
  return affine_matrix_to_r(affineXform, transpose, matrix3x3);
}

// [[Rcpp::export]]
NumericMatrix cmtk_mat2dof_cpp(NumericMatrix m, Nullable<NumericVector> centre = R_NilValue,
                               bool transpose = true) {
  check_square_4x4(m);

  cmtk::Types::Coordinate matrix[4][4];
  for (int row = 0; row < 4; ++row) {
    for (int col = 0; col < 4; ++col) {
      matrix[row][col] = m(row, col);
    }
  }

  if (transpose) {
    transpose4x4(matrix);
  }

  cmtk::AffineXform::SmartPtr xform;
  try {
    xform = cmtk::AffineXform::SmartPtr(new cmtk::AffineXform(matrix));
  } catch (const cmtk::AffineXform::MatrixType::SingularMatrixException&) {
    stop("Singular affine matrix cannot be converted to CMTK parameters.");
  }

  if (centre.isNotNull()) {
    NumericVector c(centre);
    if (c.size() != 3) {
      stop("`centre` must be a numeric vector of length 3.");
    }
    cmtk::Types::Coordinate cc[3] = {c[0], c[1], c[2]};
    xform->ChangeCenter(cmtk::FixedVector<3, cmtk::Types::Coordinate>::FromPointer(cc));
  }

  cmtk::CoordinateVector v;
  xform->GetParamVector(v);
  if (v.Dim != 15) {
    stop("Internal error: expected 15 CMTK affine parameters, got %d.", v.Dim);
  }

  NumericMatrix out(5, 3);
  for (int i = 0; i < 15; ++i) {
    out(i / 3, i % 3) = v.Elements[i];
  }

  return out;
}

// [[Rcpp::export]]
std::string cmtk_version_string() {
  return std::string(CMTK_VERSION_STRING);
}

// [[Rcpp::export]]
bool cmtk_write_affine_list_cpp(NumericMatrix params, std::string folder,
                                std::string reference = "reference",
                                std::string floating = "floating") {
  if (params.nrow() != 5 || params.ncol() != 3) {
    stop("`params` must be a 5x3 matrix.");
  }
  if (folder.empty()) {
    stop("`folder` must be a non-empty path.");
  }

  cmtk::Types::Coordinate raw[15];
  for (int i = 0; i < 15; ++i) {
    raw[i] = params(i / 3, i % 3);
  }
  cmtk::AffineXform affine(raw);

  cmtk::ClassStreamOutput stream;

  stream.Open(folder, "studylist", cmtk::ClassStreamOutput::MODE_WRITE);
  if (!stream.IsValid()) {
    stop("Could not open `%s/studylist` for writing.", folder);
  }
  stream.Begin("source");
  stream.WriteString("studyname", reference);
  stream.End();
  stream.Begin("source");
  stream.WriteString("studyname", floating);
  stream.End();
  stream.Close();

  stream.Open(folder, "registration", cmtk::ClassStreamOutput::MODE_WRITE);
  if (!stream.IsValid()) {
    stop("Could not open `%s/registration` for writing.", folder);
  }
  stream.Begin("registration");
  stream.WriteString("reference_study", reference);
  stream.WriteString("floating_study", floating);
  stream << affine;
  stream.End();
  stream.Close();

  return true;
}
