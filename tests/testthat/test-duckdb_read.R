# table_exists ----
test_that("duckdb_table_exists returnerer TRUE for eksisterende tabell og FALSE for manglende eller tomt tabell", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS x")
  expect_true(duckdb_table_exists(con, "testtab"))
  expect_false(duckdb_table_exists(con, "finnes_ikke"))
  expect_false(duckdb_table_exists(con, ""))
})

# get_tables ----
test_that("duckdb_get_tables returnerer alle tabeller", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1")
  DBI::dbExecute(con, "CREATE TABLE c AS SELECT 1")
  tabs <- duckdb_get_tables(con)
  expect_setequal(tabs, c("a", "b", "c"))
})

# get_columns ----
test_that("duckdb_get_columns returnerer kolonnenavn", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a, 'x' AS b")
  cols <- duckdb_get_columns(con = con, tablename = "testtab")
  expect_identical(cols, c("a", "b"))
})

test_that("duckdb_get_columns feiler for ukjent tabell", {
  con <- local_test_duckdb()
  expect_error(duckdb_get_columns(con, "finnes_ikke"))
})

# get_column_types ----

test_that("duckdb_get_column_types returnerer navngitt vektor med typer", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER, navn VARCHAR, verdi DOUBLE)")
  types <- duckdb_get_column_types(con, "testtab")
  expect_type(types, "character")
  expect_identical(names(types), c("id", "navn", "verdi"))
  expect_identical(unname(types), c("INTEGER", "VARCHAR", "DOUBLE"))
})

test_that("duckdb_get_column_types feiler dersom tabellen ikke finnes", {
  con <- local_test_duckdb()
  expect_error(duckdb_get_column_types(con, "finnes_ikke"), "finnes ikke")
})

test_that("duckdb_get_column_types kan brukes direkte i duckdb_ensure_columns", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE source (id INTEGER, navn VARCHAR)")
  DBI::dbExecute(con, "CREATE TABLE target (id INTEGER)")
  types <- duckdb_get_column_types(con, "source")
  duckdb_ensure_columns(con, "target", types["navn"])
  expect_setequal(duckdb_get_columns(con, "target"), c("id", "navn"))
})

test_that("duckdb_get_column_types fungerer for tom tabell", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER, txt VARCHAR)")
  types <- duckdb_get_column_types(con, "testtab")
  expect_identical(types, c(id = "INTEGER", txt = "VARCHAR"))
})

# fetch_table ----
test_that("duckdb_fetch_table returnerer data.table", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a, 'x' AS b")
  dt <- duckdb_fetch_table(con, "testtab")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_identical(names(dt), c("a", "b"))
})

test_that("duckdb_fetch_table respekterer limit", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT * FROM range(100)")
  dt <- duckdb_fetch_table(con, "testtab", limit = 10)
  expect_equal(nrow(dt),10)
})

test_that("duckdb_fetch_table feiler for ukjent tabell", {
  con <- local_test_duckdb()
  expect_error(duckdb_fetch_table(con, "finnes_ikke"), "finnes ikke i duckdb")
})

