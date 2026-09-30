test_that("duckdb_save_file skriver parquet-fil", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS id, 'a' AS txt")
  filepath <- tempfile(fileext = ".parquet")
  duckdb_save_file(con, source = "testtab", filepath = filepath)
  expect_true(file.exists(filepath))
  expect_gt(file.info(filepath)$size,0)
})

test_that("duckdb_save_file skriver csv-fil", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS id, 'a' AS txt")
  filepath <- tempfile(fileext = ".csv")
  duckdb_save_file(con, source = "testtab", filepath = filepath)
  expect_true(file.exists(filepath))
  expect_gt(file.info(filepath)$size,0)
})

test_that("duckdb_save_file krever støttet filendelse", {
  con <- local_test_duckdb()
  expect_error(duckdb_save_file(con, source = "testtab", filepath = "test.xlsx"))
})

test_that("duckdb_save_file kan skrive SQL-uttrykk", {
  con <- local_test_duckdb()
  filepath <- tempfile(fileext = ".csv")
  duckdb_save_file(con, source = "(SELECT 1 AS id, 'a' AS txt)", filepath = filepath)
  expect_true(file.exists(filepath))
})
