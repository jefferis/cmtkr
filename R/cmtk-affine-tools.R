#' Convert CMTK affine representation to matrix form
#'
#' @param reg Path to an affine CMTK transform/list, or numeric CMTK affine
#'   parameters (length-15 vector or 5x3 matrix).
#' @param Transpose Whether to transpose matrix orientation to match R
#'   conventions. Default `TRUE`.
#' @param version When `TRUE`, return bundled CMTK version string.
#' @param matrix3x3 Whether to return only the top-left 3x3 matrix.
#' @return Numeric matrix (4x4 or 3x3).
#' @export
cmtk_dof2mat <- function(reg, Transpose = TRUE, version = FALSE, matrix3x3 = FALSE) {
  if (isTRUE(version)) {
    return(cmtk_version_string())
  }

  if (is.character(reg)) {
    if (length(reg) != 1L) {
      stop("`reg` must be a single path when character input is used.")
    }
    return(cmtk_dof2mat_path(path.expand(reg), transpose = Transpose, matrix3x3 = matrix3x3))
  }

  if (!is.numeric(reg)) {
    stop("`reg` must be a character path or numeric CMTK affine parameters.")
  }

  params <- reg
  if (is.matrix(params)) {
    if (!all(dim(params) == c(5L, 3L))) {
      stop("Numeric matrix input must be 5x3 CMTK affine parameters.")
    }
    params <- as.numeric(t(params))
  }
  cmtk_dof2mat_params(params = as.numeric(params), transpose = Transpose, matrix3x3 = matrix3x3)
}

#' Convert homogeneous affine matrix to CMTK affine parameters
#'
#' @param m 4x4 homogeneous affine matrix.
#' @param f Optional output transform path. When provided, writes transform to
#'   file and returns `TRUE`.
#' @param centre Optional numeric length-3 center for decomposition.
#' @param Transpose Whether to transpose input matrix before decomposition.
#'   Default `TRUE`.
#' @param version When `TRUE`, return bundled CMTK version string.
#' @return 5x3 numeric CMTK affine parameter matrix, or `TRUE` when `f` is set.
#' @export
cmtk_mat2dof <- function(m, f = NULL, centre = NULL, Transpose = TRUE, version = FALSE) {
  if (isTRUE(version)) {
    return(cmtk_version_string())
  }

  if (!is.null(f)) {
    ok <- cmtk_mat2dof_cpp(m = m, centre = centre, transpose = Transpose, outfile = path.expand(f))
    return(isTRUE(ok))
  }

  params <- cmtk_mat2dof_cpp(m = m, centre = centre, transpose = Transpose, outfile = NULL)
  rownames(params) <- c("xlate", "rotate", "scale", "shear", "center")
  params
}

# nat-compatible aliases
#' @export
cmtk.dof2mat <- cmtk_dof2mat
#' @export
cmtk.mat2dof <- cmtk_mat2dof
