test_that("get_all_tabdims returnerer unike sorterte dimensjoner", {
  con <- "mock_connection"
  dt <- data.table::data.table(TAB1 = c("GEO", "AAR"), 
                               TAB2 = c("KJONN", NA), 
                               TAB3 = c("ALDER", "GEO"))
  
  mock_connect <- mockery::mock(con)
  mock_query <- mockery::mock(dt)
  mock_disconnect <- mockery::mock(NULL)
  
  mockery::stub(get_all_tabdims, "connect_khelsa", mock_connect)
  mockery::stub(get_all_tabdims, "DBI::dbGetQuery", mock_query)
  mockery::stub(get_all_tabdims, "DBI::dbDisconnect", mock_disconnect)
  out <- get_all_tabdims()
  expect_identical(out, c("AAR", "ALDER", "GEO", "KJONN"))
  mockery::expect_called(mock_connect, 1)
  mockery::expect_called(mock_query, 1)
  mockery::expect_called(mock_disconnect, 1)
})

test_that("get_all_tabdims bruker korrekt SQL", {
  con <- "mock_connection"
  mock_connect <- mockery::mock(con)
  mock_query <- mockery::mock(data.frame(TAB1 = character(),
                                         TAB2 = character(),
                                         TAB3 = character())
  )
  
  mockery::stub(get_all_tabdims, "connect_khelsa", mock_connect)
  mockery::stub(get_all_tabdims, "DBI::dbGetQuery", mock_query)
  mockery::stub(get_all_tabdims, "DBI::dbDisconnect", mock_disconnect)
  mock_disconnect <- mockery::mock(NULL)
  get_all_tabdims()
  sql <- mockery::mock_args(mock_query)[[1]][[2]]
  expect_match(sql, "SELECT TAB1, TAB2, TAB3")
  expect_match(sql, "FROM FILGRUPPER")
  expect_match(sql, "VERSJONFRA <=")
  expect_match(sql, "VERSJONTIL >")
})

test_that("set_option_dim_tab oppdaterer option", {
  withr::local_options(list(khtools.dim.tab = NULL))
  mockery::stub(set_option_dim_tab, "get_all_tabdims", 
                function() c("AAR", "ALDER", "GEO"))
  out <- set_option_dim_tab()
  expect_identical(out, c("AAR", "ALDER", "GEO"))
  expect_identical(getOption("khtools.dim.tab"), c("AAR", "ALDER", "GEO"))
})
