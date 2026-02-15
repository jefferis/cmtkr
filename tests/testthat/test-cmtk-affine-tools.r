context("affine CMTK conversion helpers")

test_that("cmtk_dof2mat handles numeric params", {
  params <- rbind(
    xlate = c(2, -3, 4),
    rotate = c(0.2, -0.1, 0.3),
    scale = c(1.1, 0.9, 1.2),
    shear = c(0.01, -0.02, 0.03),
    center = c(10, 20, 30)
  )

  m <- cmtk_dof2mat(params)
  expect_true(is.matrix(m))
  expect_equal(dim(m), c(4, 4))
  expect_true(is.character(cmtk.dof2mat(version = TRUE)))
  expect_true(is.character(cmtk.mat2dof(diag(4), version = TRUE)))
})

test_that("mat2dof and dof2mat roundtrip matrix", {
  params <- rbind(
    xlate = c(1, 2, 3),
    rotate = c(0.1, 0.05, -0.2),
    scale = c(1.05, 0.95, 1.1),
    shear = c(0.02, 0.01, -0.03),
    center = c(5, 6, 7)
  )
  m <- cmtk_dof2mat(params)

  p2 <- cmtk_mat2dof(m, centre = params["center", ])
  expect_equal(dim(p2), c(5, 3))
  expect_equal(rownames(p2), c("xlate", "rotate", "scale", "shear", "center"))

  m2 <- cmtk_dof2mat(p2)
  expect_equal(m2, m, tolerance = 1e-6)
})

test_that("aliases work and writing transform path works", {
  params <- rbind(
    xlate = c(-2, 1, 0.5),
    rotate = c(0.01, 0.02, -0.03),
    scale = c(0.99, 1.01, 1.02),
    shear = c(0, 0, 0),
    center = c(0, 0, 0)
  )
  m <- cmtk.dof2mat(params)

  tf <- tempfile(fileext = ".list")
  ok <- cmtk.mat2dof(m, f = tf)
  expect_true(isTRUE(ok))
  expect_true(dir.exists(tf))
  expect_true(file.exists(file.path(tf, "registration")))
  expect_true(file.exists(file.path(tf, "studylist")))

  mr <- cmtk.dof2mat(tf)
  expect_equal(mr, m, tolerance = 1e-6)
})
