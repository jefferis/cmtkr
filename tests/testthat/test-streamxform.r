context("transformations")

test_that("streamxform works",{
  reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtk')
  m=matrix(rnorm(300,mean = 50), ncol=3)
  # check that we get a matrix
  expect_is(m2<-streamxform(m, reg), "matrix")
})
