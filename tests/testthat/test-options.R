test_that("get_all_tabdims returnerer unike sorterte dimensjoner", {
  path <- "test.accdb"
  con <- "mock_connection"
  dt <- data.table::data.table(TAB1 = c("GEO", "AAR"), 
                               TAB2 = c("KJONN", NA_character_), 
                               TAB3 = c("ALDER", "GEO"))
  
  mock_connect <- mockery::mock(con)
  mock_query <- mockery::mock(dt)
  mock_disconnect <- mockery::mock(NULL)
  
  mockery::stub(get_all_tabdims, "connect_access", mock_connect)
  mockery::stub(get_all_tabdims, "DBI::dbGetQuery", mock_query)
  mockery::stub(get_all_tabdims, "DBI::dbDisconnect", mock_disconnect)
  out <- get_all_tabdims(path)
  expect_setequal(out, c("AAR", "ALDER", "GEO", "KJONN", "TAB1", "TAB2", "TAB3"))
  mockery::expect_called(mock_connect, 1)
  mockery::expect_called(mock_query, 1)
  mockery::expect_called(mock_disconnect, 1)
  expect_identical(
    mockery::mock_args(mock_connect)[[1L]][[1L]],
    path
  )
})

test_that("get_all_tabdims bruker korrekt SQL", {
  path <- "test.accdb"
  con <- "mock_connection"
  mock_connect <- mockery::mock(con)
  mock_query <- mockery::mock(data.frame(TAB1 = character(),
                                         TAB2 = character(),
                                         TAB3 = character())
  )
  mock_disconnect <- mockery::mock(NULL)
  
  mockery::stub(get_all_tabdims, "connect_access", mock_connect)
  mockery::stub(get_all_tabdims, "DBI::dbGetQuery", mock_query)
  mockery::stub(get_all_tabdims, "DBI::dbDisconnect", mock_disconnect)
  get_all_tabdims(path)
  sql <- mockery::mock_args(mock_query)[[1]][[2]]
  expect_match(sql, "SELECT TAB1, TAB2, TAB3")
  expect_match(sql, "FROM FILGRUPPER")
  expect_match(sql, "VERSJONFRA <=")
  expect_match(sql, "VERSJONTIL >")
})
