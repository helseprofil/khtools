test_that("connect_access stopper dersom databasefil mangler", {
  withr::local_options(
    list(
      khtools.root = tempdir(),
      test.db = "missing.accdb"
    ))
  
  expect_error(connect_access("test.db"), "Finner ikke databasefilen")
})

test_that("connect_access bruker korrekt connection string", {
  path <- tempfile(fileext = ".accdb")
  file.create(path)
  withr::local_options(
    list(
      khtools.root = dirname(path),
      test.db = basename(path)
    ))
  mock <- mockery::mock("connection")
  mockery::stub(connect_access, "DBI::dbConnect", mock)
  connect_access("test.db")
  mockery::expect_called(mock, 1)
  args <- mockery::mock_args(mock)[[1]]
  expect_equal(args$.connection_string,
               sprintf("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s;", 
                       normalizePath(path, winslash = "/", mustWork = FALSE)))
})

test_that("connect_khelsa bruker khtools.db_khelsa", {
  mock <- mockery::mock(NULL)
  mockery::stub(connect_khelsa, "connect_access", mock)
  connect_khelsa()
  mockery::expect_called(mock, 1)
  expect_identical(
    mockery::mock_args(mock)[[1]][[1]], 
    "khtools.db_khelsa")
})

test_that("connect_geokoder bruker khtools.db_geo", {
  mock <- mockery::mock(NULL)
  mockery::stub(connect_geokoder, "connect_access", mock)
  connect_geokoder()
  mockery::expect_called(mock, 1)
  
  expect_identical(
    mockery::mock_args(mock)[[1]][[1]],
    "khtools.db_geo"
  )
})
