context("transformations")

test_that("streamxform works",{
  reg=system.file("extdata","cmtk","FCWB_JFRC2_01_warp_level-01.list", package='cmtk')
  m=matrix(rnorm(300), ncol=3)
  # right now just test that we get back what we put in
  expect_equal(streamxform(m, reg),m)
})
