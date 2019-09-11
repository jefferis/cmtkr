context("transformations")

test_that("streamxform works",{
  reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')
  m=matrix(rnorm(300,mean = 50), ncol=3)
  expect_is(m2<-streamxform(m, reg), "matrix")

  expect_equal(streamxform(m2, c("--inverse", reg)), m, info="round trip test")
})


test_that("compare with nat",{
  skip_if_not_installed('nat')
  skip_if_not(isTRUE(nat::cmtk.version()>'2.0'))

  reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')
  m=matrix(rnorm(300,mean = 50), ncol=3)
  # check that we get a matrix
  expect_equal(streamxform(m, reg), nat::xform(m, reg, direction='forward'))

  expect_equal(streamxform(m, reg, affineonly = TRUE),
               nat::xform(m, reg, direction='forward', transformtype='affine'))
})
