test_that("connect_access stopper dersom databasefil mangler", {
  path <- file.path(tempdir(), "missing.accdb")
  expect_error(connect_access("test.db"), "Finner ikke databasefilen")
})

test_that("connect_access bruker korrekt connection string", {
  path <- tempfile(fileext = ".accdb")
  file.create(path)
  mock_connect <- mockery::mock("connection")
  mockery::stub(connect_access, "DBI::dbConnect", mock_connect)
  connect_access(path)
  mockery::expect_called(mock_connect, 1)
  args <- mockery::mock_args(mock_connect)[[1]]
  expect_equal(args$.connection_string,
               sprintf("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s;", 
                       path))
})
