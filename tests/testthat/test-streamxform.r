context("transformations")

test_that("streamxform works",{
  reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtk')
  m=matrix(rnorm(300,mean = 50), ncol=3)
  expect_is(m2<-streamxform(m, reg), "matrix")

  expect_equal(streamxform(m2, c("--inverse", reg)), m, info="round trip test")
})
