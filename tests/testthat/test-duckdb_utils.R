# ensure_columns ----
test_that("duckdb_ensure_columns oppretter manglende kolonner", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER)")
  duckdb_ensure_columns(con, table = "testtab", cols = c(navn = "VARCHAR", alder = "INTEGER"))
  expect_setequal(duckdb_get_columns(con, "testtab"), c("id", "navn", "alder"))
})

test_that("duckdb_ensure_columns håndterer liste", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER)")
  duckdb_ensure_columns(con, "testtab", list(navn = "VARCHAR", alder = "INTEGER"))
  expect_setequal(duckdb_get_columns(con, "testtab"), c("id", "navn", "alder"))
})

test_that("duckdb_ensure_columns er idempotent", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER)")
  
  expect_no_error(duckdb_ensure_columns(con, "testtab", c(navn = "VARCHAR")))
  expect_no_error(duckdb_ensure_columns(con, "testtab", c(navn = "VARCHAR")))
})

test_that("duckdb_ensure_columns krever navngitt input", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab (id INTEGER)")
  expect_error(duckdb_ensure_columns(con, "testtab", c("VARCHAR", "INTEGER")), "navngitt")
})

# merge_tables ----
test_that("duckdb_merge_tables merger nye kolonner", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1 AS id, 'A' AS navn")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1 AS id, 100 AS verdi")
  
  duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", join_cols = "id")
  cols <- duckdb_get_columns(con, "a")
  expect_true("verdi" %in% cols)
})

test_that("duckdb_merge_tables kan skrive til ny tabell", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1 AS id")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1 AS id, 100 AS verdi")
  
  duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", join_cols = "id", result = "c")
  expect_true(duckdb_table_exists(con, "a"))
  expect_true(duckdb_table_exists(con, "b"))
  expect_true(duckdb_table_exists(con, "c"))
  expect_true("verdi" %in% duckdb_get_columns(con, "c"))
})

test_that("duckdb_merge_tables håndterer ingen nye kolonner", {
  silent_test()
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1 AS id")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1 AS id")
  expect_no_error(duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", join_cols = "id"))
})

test_that("duckdb_merge_tables feiler om join-kolonner ikke finnes i begge tabeller", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1 AS id")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1 AS id, 100 AS verdi")
  expect_error(duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", join_cols = "finnes_ikke"), "Join-kolonner")
})

test_that("duckdb_merge_tables feiler hvis mergeto eller mergefrom mangler i duckdb", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1 AS id")
  expect_error(duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", join_cols = "id"), "Tabell 'a' finnes ikke")
  expect_error(duckdb_merge_tables(con, mergeto = "b", mergefrom = "a", join_cols = "id"), "Tabell 'a' finnes ikke")
})

test_that("duckdb_merge_tables krever join_cols", {
  expect_error(duckdb_merge_tables(con, mergeto = "a", mergefrom = "b"), "join_cols")
})

test_that("duckdb_merge_tables feiler om result = mergefrom", {
  expect_error(duckdb_merge_tables(con, mergeto = "a", mergefrom = "b", result = "b", join_cols = "id"), "mergefrom")
})
