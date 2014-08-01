context("transformations")

test_that("streamxform works",{
  reg=system.file("extdata","cmtkr","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')
  m=matrix(rnorm(300,mean = 50), ncol=3)
  expect_is(m2<-streamxform(m, reg), "matrix")

  expect_equal(streamxform(m2, c("--inverse", reg)), m, info="round trip test")
})

if(require('nat', quietly = TRUE) && isTRUE(cmtkr.version()>'2.0')) {
  test_that("compare with nat",{
    reg=system.file("extdata","cmtkr","FCWB_JFRC2_01_warp_level-01.list", package='cmtkr')
    m=matrix(rnorm(300,mean = 50), ncol=3)
    # check that we get a matrix
    expect_equal(streamxform(m, reg), xform(m, reg, direction='forward'))
  })
}
