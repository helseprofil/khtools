# sql_quote_I ----
test_that("sql_quote_I returnerer SQL-objekt", {
  con <- local_test_duckdb()
  x <- sql_quote_I(con,c("tabell", "kolonne"))
  expect_true(inherits(x, "SQL"))
  expect_length(x,2)
})

test_that("sql_quote_I quoter identifikatorer ved behov", {
  con <- local_test_duckdb()
  expect_identical(as.character(sql_quote_I(con, "RATE.n")), '"RATE.n"')
})

# sql_quote_S ----

test_that("sql_quote_S returnerer SQL-objekt", {
  con <- local_test_duckdb()
  x <- sql_quote_S(con, c("abc", "def"))
  expect_true(inherits(x, "SQL"))
  expect_length(x, 2)
})

test_that("sql_quote_S quoter strenger", {
  con <- local_test_duckdb()
  x <- as.character(sql_quote_S(con, "abc"))
  expect_identical(x, "'abc'")
})

test_that("sql_quote_S escaper apostrof korrekt", {
  con <- local_test_duckdb()
  x <- as.character(sql_quote_S(con, "O'Reilly"))
  expect_identical(x, "'O''Reilly'")
})
