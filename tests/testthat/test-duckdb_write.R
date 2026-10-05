# write_table ----
test_that("duckdb_write_table skriver tabell", {
  con <- local_test_duckdb()
  dt <- data.table::data.table(id = 1:3, navn = c("a", "b", "c"))
  
  duckdb_write_table(con = con, tablename = "testtab", data = dt)
  expect_true(duckdb_table_exists(con, "testtab"))
  expect_identical(duckdb_get_columns(con, "testtab"), c("id", "navn"))
})

test_that("duckdb_write_table overskriver eksisterende tabell", {
  con <- local_test_duckdb()
  duckdb_write_table(con, "testtab", data.frame(a = 1))
  duckdb_write_table(con, "testtab", data.frame(b = 1), overwrite = TRUE)
  expect_identical(duckdb_get_columns(con, "testtab"), "b")
})

# drop_tables ----

test_that("duckdb_drop_tables sletter tabell", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS x")
  duckdb_drop_tables(con, "testtab")
  expect_false(duckdb_table_exists(con, "testtab"))
})

test_that("duckdb_drop_tables håndterer flere tabeller", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE a AS SELECT 1")
  DBI::dbExecute(con, "CREATE TABLE b AS SELECT 1")
  DBI::dbExecute(con, "CREATE TABLE c AS SELECT 1")
  duckdb_drop_tables(con, c("a", "b", "c"))
  expect_setequal(duckdb_get_tables(con),character())
})

test_that("duckdb_drop_tables gjør ingenting for character(0) eller NULL", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a")
  expect_no_error(duckdb_drop_tables(con, character(0)))
  expect_true(duckdb_table_exists(con, "testtab"))
  expect_no_error(duckdb_drop_tables(con, NULL))
  expect_true(duckdb_table_exists(con, "testtab"))
})

# replace_table ----
test_that("duckdb_replace_table erstatter target med source", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE target AS SELECT 1 AS a")
  DBI::dbExecute(con, "CREATE TABLE source AS SELECT 2 AS b")
  duckdb_replace_table(con, target = "target", source = "source")
  expect_identical(duckdb_get_columns(con, "target"), "b")
  expect_false(duckdb_table_exists(con, "source"))
})

test_that("duckdb_replace_table feiler dersom target er source", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1")
  expect_error(duckdb_replace_table(con, target = "testtab", source = "testtab"),
               "samme tabell")
})

# write_and_replace_table_from_R ----
test_that("duckdb_write_and_replace_table_from_R erstatter tabell", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a")
  dt <- data.table::data.table(b = c(10, 20))
  duckdb_write_and_replace_table_from_R(con = con, tablename = "testtab", data = dt)
  expect_identical(duckdb_get_columns(con, "testtab"), "b")
  expect_equal(nrow(duckdb_fetch_table(con, "testtab")),2)
})

# replace_existing_table ----
test_that("duckdb_replace_existing_table erstatter tabell fra query", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a")
  duckdb_replace_existing_table(con = con, target = "testtab", select_sql = "SELECT 2 AS b")
  expect_identical(duckdb_get_columns(con, "testtab"), "b")
  dt <- duckdb_fetch_table(con, "testtab")
  expect_equal(dt$b,2)
})

test_that("duckdb_replace_existing_table kan bruke target i select", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT * FROM range(100)")
  duckdb_replace_existing_table(
    con = con,
    target = "testtab",
    select_sql = sprintf("SELECT * FROM %s LIMIT 10",sql_quote_I(con, "testtab"))
  )
  expect_equal(nrow(duckdb_fetch_table(con, "testtab")),10)
})

test_that("duckdb_replace_existing_table feiler dersom target ikke finnes", {
  con <- local_test_duckdb()
  expect_error(
    duckdb_replace_existing_table(con = con, 
                                    target = "finnes_ikke", 
                                    select_sql = "SELECT 1 AS a"),
    "finnes ikke"
  )
})

# create_table ----
test_that("duckdb_create_table oppretter ny tabell", {
  con <- local_test_duckdb()
  
  duckdb_create_new_table(con = con,
                          target = "testtab",
                          select_sql = "SELECT 1 AS a")
  
  expect_true(duckdb_table_exists(con, "testtab"))
  expect_identical(duckdb_get_columns(con, "testtab"), "a")
})

test_that("duckdb_create_table oppretter tabell med korrekt innhold", {
  con <- local_test_duckdb()
  duckdb_create_new_table(con = con, 
                          target = "testtab", 
                          select_sql = "SELECT 1 AS a, 'x' AS b")
  
  dt <- duckdb_fetch_table(con, "testtab")
  
  expect_equal(nrow(dt), 1)
  expect_identical(names(dt), c("a", "b"))
})

test_that("duckdb_create_table feiler dersom target allerede finnes", {
  con <- local_test_duckdb()
  DBI::dbExecute(con, "CREATE TABLE testtab AS SELECT 1 AS a")
  
  expect_error(duckdb_create_new_table(con = con, 
                                       target = "testtab", 
                                       select_sql = "SELECT 2 AS b"),
    "finnes"
  )
  
})
