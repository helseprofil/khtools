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

# append_table ----
test_that("duckdb_append_table legger til rader", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS id")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 2 AS id")
  duckdb_append_table(con, target = "target", source = "source")
  dt <- duckdb_fetch_table(con, "target")
  expect_equal(nrow(dt), 2)
  expect_setequal(dt$id, c(1, 2))
})

test_that("duckdb_append_table bruker BY NAME", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target (id INTEGER, txt VARCHAR)")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 'abc' AS txt, 1 AS id")
  
  duckdb_append_table(con, target = "target", source = "source")
  dt <- duckdb_fetch_table(con, "target")
  expect_equal(dt$id, 1)
  expect_equal(dt$txt, "abc")
})

test_that("duckdb_append_table krever at target finnes", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 1 AS id")
  expect_error(duckdb_append_table(con, target = "target", source = "source"), "'target' finnes ikke")
})

test_that("duckdb_append_table krever at source finnes", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS id")
  expect_error(duckdb_append_table(con, target = "target", source = "source"), "'source' finnes ikke")
})

test_that("duckdb_append_table håndterer tom source-tabell", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS id")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 1 AS id WHERE FALSE")
  duckdb_append_table(con, target = "target", source = "source")
  expect_equal(nrow(duckdb_fetch_table(con, "target")), 1)
})

test_that("duckdb_append_table legger til kolonner som kun finnes i source", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS A")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 2 AS A, 100 AS B")
  duckdb_append_table(con, target = "target", source = "source")
  dt <- duckdb_fetch_table(con, "target")
  expect_setequal(names(dt), c("A", "B"))
  expect_equal(nrow(dt), 2)
  expect_true(is.na(dt$B[1]))
  expect_equal(dt$B[2], 100)
})

test_that("duckdb_append_table legger til kolonner som kun finnes i target", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS A, 10 AS B")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 2 AS A")
  duckdb_append_table(con, target = "target", source = "source")
  dt <- duckdb_fetch_table(con, "target")
  expect_setequal(names(dt), c("A", "B"))
  expect_equal(nrow(dt), 2)
  expect_true(is.na(dt$B[2]))
})

test_that("duckdb_append_table håndterer kolonner som finnes i begge retninger", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS A, 10 AS B")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 2 AS A, 20 AS C")
  duckdb_append_table(con, target = "target", source = "source")
  dt <- duckdb_fetch_table(con, "target")
  expect_setequal(names(dt), c("A", "B", "C"))
  expect_equal(nrow(dt), 2)
  expect_true(is.na(dt$C[1]))
  expect_true(is.na(dt$B[2]))
})
