is.cmtk_xformlist <- function(x) {
  inherits(x, "cmtk_xformlist")
}

xformlist_load <- function(reglist, inversionTolerance = 1e-8, affineonly = FALSE) {
  ptr <- .Call("_cmtkr_xformlist_load", PACKAGE = "cmtkr",
               reglist, inversionTolerance, affineonly)
  structure(
    list(
      ptr = ptr,
      reglist = reglist,
      inversionTolerance = inversionTolerance,
      affineonly = affineonly
    ),
    class = "cmtk_xformlist"
  )
}

print.cmtk_xformlist <- function(x, ...) {
  n_reg <- length(x$reglist)
  cat("<cmtk_xformlist> ", n_reg, " transform", if (n_reg == 1) "" else "s", "\n", sep = "")
  cat("  inversionTolerance: ", format(x$inversionTolerance, digits = 6), "\n", sep = "")
  cat("  affineonly: ", x$affineonly, "\n", sep = "")
  invisible(x)
}

summary.cmtk_xformlist <- function(object, ...) {
  object
}

streamxform <- function(points, reglist, inversionTolerance = 1e-8, affineonly = FALSE) {
  if (is.cmtk_xformlist(reglist)) {
    return(.Call("_cmtkr_streamxform_ptr", PACKAGE = "cmtkr", points, reglist$ptr))
  }
  .Call("_cmtkr_streamxform", PACKAGE = "cmtkr", points, reglist, inversionTolerance, affineonly)
}
