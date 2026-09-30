test_that("duckdb_init oppretter gyldig connection", {
  con <- khtools::duckdb_init("test_init")
  expect_true(DBI::dbIsValid(con))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_init krever dbname", {
  expect_error(khtools::duckdb_init(), "dbname")
})

test_that("duckdb_init starter med tom database", {
  con <- khtools::duckdb_init("test_empty")
  DBI::dbExecute(con, "CREATE TABLE test AS SELECT 1 AS x")
  DBI::dbDisconnect(con)
  con <- khtools::duckdb_init("test_empty")
  expect_length(khtools::duckdb_get_tables(con),0)
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_clean kjører uten feil", {
  con <- khtools::duckdb_init("test_clean")
  DBI::dbExecute(con, "CREATE TABLE test AS SELECT * FROM range(1000)")
  expect_no_error(khtools::duckdb_clean(con))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_clean håndterer lukket connection", {
  con <- khtools::duckdb_init("test_clean_closed")
  DBI::dbDisconnect(con)
  expect_no_error(khtools::duckdb_clean(con))
})

test_that("duckdb_shutdown lukker connection", {
  con <- khtools::duckdb_init("test_shutdown")
  khtools::duckdb_shutdown(con)
  expect_false(DBI::dbIsValid(con))
})

test_that("duckdb_shutdown sletter databasefilen", {
  con <- khtools::duckdb_init("test_delete")
  dbfile <- DBI::dbGetInfo(con)$dbname
  expect_true(file.exists(dbfile))
  khtools::duckdb_shutdown(con)
  expect_false(file.exists(dbfile))
})

test_that("duckdb_shutdown håndterer NULL", {
  expect_no_error(khtools::duckdb_shutdown(NULL))
})
