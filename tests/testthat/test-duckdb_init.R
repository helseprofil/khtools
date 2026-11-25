test_that("duckdb_init oppretter gyldig connection", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_init", mem_limit_gb = 1, path = path)
  expect_true(DBI::dbIsValid(con))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_init krever dbname", {
  path <- withr::local_tempdir()
  expect_error(khtools::duckdb_init(path = path, mem_limit_gb = 1), "dbname")
})

test_that("duckdb_init avviser ugyldig dbname", {
  path <- withr::local_tempdir()
  expect_error(khtools::duckdb_init(dbname = "", path = path, mem_limit_gb = 1), 
               "dbname")
  expect_error(khtools::duckdb_init(dbname = NA_character_, path = path,mem_limit_gb = 1),
               "dbname"
  )
})


test_that("duckdb_init starter med tom database", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init("test_empty", mem_limit_gb = 1, path = path)
  invisible(DBI::dbExecute(con, "CREATE TABLE test AS SELECT 1 AS x"))
  khtools::duckdb_disconnect(con)
  con <- khtools::duckdb_init("test_empty", mem_limit_gb = 1, path = path)
  expect_length(khtools::duckdb_get_tables(con),0)
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_init bruker path fra duckdbopts", {
  root <- withr::local_tempdir()
  configured_path <- file.path(root, "configured")
  withr::local_options(khtools.duckdbopts = list(
    default = list(mem_limit_gb = 1, path = configured_path)))
  
  con <- khtools::duckdb_init(dbname = "test_config")
  dbfile <- DBI::dbGetInfo(con)$dbname
  expect_equal(fs::path_norm(dbfile),
               fs::path_norm(file.path(configured_path,"test_config.duckdb")))
  
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_init setter temp_directory under databasepath", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_temp_dir", mem_limit_gb = 1, path = path)
  temp_dir <- DBI::dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")$temp_directory[[1L]]
  
  expect_equal(fs::path_norm(temp_dir),
               fs::path_norm(file.path(path, "temp"))
  )
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_clean kjører uten feil", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init("test_clean", mem_limit_gb = 1, path = path)
  invisible(DBI::dbExecute(con, "CREATE TABLE test AS SELECT * FROM range(1000)"))
  expect_no_error(khtools::duckdb_clean(con))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_clean håndterer NULL", {
  expect_no_error(khtools::duckdb_clean(NULL))
})

test_that("duckdb_clean håndterer lukket connection", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init("test_clean_closed", mem_limit_gb = 1, path = path)
  khtools::duckdb_disconnect(con)
  expect_no_error(khtools::duckdb_clean(con))
  con <- khtools::duckdb_connect(dbname = "test_clean_closed",mem_limit_gb = 1, path = path)
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_shutdown lukker connection", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init("test_shutdown", mem_limit_gb = 1, path = path)
  khtools::duckdb_shutdown(con)
  expect_false(DBI::dbIsValid(con))
})

test_that("duckdb_shutdown sletter databasefilen og tempmappen", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_delete", mem_limit_gb = 1, path = path)
  dbfile <- DBI::dbGetInfo(con)$dbname
  temp_dir <- file.path(path, "temp")
  expect_true(file.exists(dbfile))
  expect_true(fs::dir_exists(temp_dir))
  khtools::duckdb_shutdown(con)
  expect_false(file.exists(dbfile))
  expect_false(fs::file_exists(paste0(dbfile, ".wal")))
  expect_false(fs::dir_exists(temp_dir))
})

test_that("duckdb_shutdown håndterer NULL", {
  expect_no_error(khtools::duckdb_shutdown(NULL))
})

test_that("duckdb_shutdown håndterer lukket connection uten feil", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_shutdown_closed", mem_limit_gb = 1, path = path)
  khtools::duckdb_disconnect(con)
  expect_no_error(khtools::duckdb_shutdown(con))
})

test_that("duckdb_connect kobler til eksisterende database", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_connect", mem_limit_gb = 1, path = path)
  invisible(DBI::dbExecute(con, "CREATE TABLE test AS SELECT 1 AS x"))
  
  khtools::duckdb_disconnect(con)
  con <- khtools::duckdb_connect(dbname = "test_connect", mem_limit_gb = 1, path = path)
  expect_true(DBI::dbIsValid(con))
  expect_true(khtools::duckdb_table_exists(con = con, tablename = "test"))
  result <- DBI::dbGetQuery(con, "SELECT x FROM test")
  expect_equal(result$x, 1)
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_connect tømmer ikke eksisterende database", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_connect_keeps_tables", mem_limit_gb = 1, path = path)
  invisible(DBI::dbExecute(con, paste("CREATE TABLE existing_table AS",
                                      "SELECT 1 AS id")))
  khtools::duckdb_disconnect(con)
  con <- khtools::duckdb_connect(dbname = "test_connect_keeps_tables", mem_limit_gb = 1, path = path)
  
  expect_setequal(khtools::duckdb_get_tables(con), "existing_table")
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_connect feiler når databasen ikke finnes", {
  path <- withr::local_tempdir()
  expect_error(khtools::duckdb_connect(dbname = "finnes_ikke", mem_limit_gb = 1, path = path),
               "finnes ikke")
  expect_false(fs::file_exists(file.path(path, "finnes_ikke.duckdb")))
})

test_that("duckdb_connect bruker eksplisitt path", {
  root <- withr::local_tempdir()
  path <- file.path(root, "egen_duckdb_mappe")
  con <- khtools::duckdb_init(dbname = "test_explicit_path", mem_limit_gb = 1, path = path)
  dbfile <- DBI::dbGetInfo(con)$dbname
  expect_equal(fs::path_norm(dbfile), fs::path_norm(file.path(path, "test_explicit_path.duckdb")))
  khtools::duckdb_disconnect(con)
  con <- khtools::duckdb_connect(dbname = "test_explicit_path", mem_limit_gb = 1, path = path)
  expect_true(DBI::dbIsValid(con))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_connect bruker path fra duckdbopts", {
  root <- withr::local_tempdir()
  configured_path <- file.path(root, "configured")
  withr::local_options(khtools.duckdbopts = list(
    default = list(mem_limit_gb = 1, path = configured_path)))
  
  con <- khtools::duckdb_init(dbname = "test_connect_config")
  invisible(DBI::dbExecute(con, "CREATE TABLE test AS SELECT 1 AS x"))
  khtools::duckdb_disconnect(con)
  con <- khtools::duckdb_connect(dbname = "test_connect_config")
  expect_true(DBI::dbIsValid(con))
  expect_true(khtools::duckdb_table_exists(con = con,tablename = "test"))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_connect krever dbname", {
  path <- withr::local_tempdir()
  expect_error(khtools::duckdb_connect(path = path, mem_limit_gb = 1), "dbname")
})

test_that("duckdb_disconnect lukker connection", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_disconnect", mem_limit_gb = 1, path = path)
  expect_true(DBI::dbIsValid(con))
  khtools::duckdb_disconnect(con)
  expect_false(DBI::dbIsValid(con))
})

test_that("duckdb_disconnect beholder databasefilen og tempmappen", {
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_disconnect_keeps_file", mem_limit_gb = 1, path = path)
  dbfile <- DBI::dbGetInfo(con)$dbname
  temp_dir <- file.path(path, "temp")
  expect_true(fs::file_exists(dbfile))
  expect_true(fs::dir_exists(temp_dir))
  khtools::duckdb_disconnect(con)
  expect_false(DBI::dbIsValid(con))
  expect_true(fs::file_exists(dbfile))
  expect_true(fs::dir_exists(temp_dir))
  con <- khtools::duckdb_connect(dbname = "test_disconnect_keeps_file", mem_limit_gb = 1, path = path)
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_disconnect håndterer NULL og lukket connection", {
  expect_no_error(khtools::duckdb_disconnect(NULL))
  path <- withr::local_tempdir()
  con <- khtools::duckdb_init(dbname = "test_disconnect_closed", mem_limit_gb = 1, path = path)
  khtools::duckdb_disconnect(con)
  expect_no_error(khtools::duckdb_disconnect(con))
})

test_that("duckdb_path bruker eksplisitt path", {
  root <- withr::local_tempdir()
  path <- file.path(root, "duckdb")
  result <- khtools:::duckdb_path(dbname = "test_path", path = path)
  expect_equal(fs::path_norm(result),
               fs::path_norm(file.path(path, "test_path.duckdb"))
  )
  expect_true(fs::dir_exists(path))
})

test_that("duckdb_path bruker path fra duckdbopts", {
  root <- withr::local_tempdir()
  configured_path <- file.path(root, "configured")
  withr::local_options(khtools.duckdbopts = list(default = list(mem_limit_gb = 4, path = configured_path)))
  result <- khtools:::duckdb_path(dbname = "test_configured_path")
  expect_equal(fs::path_norm(result),
               fs::path_norm(file.path(configured_path, "test_configured_path.duckdb")))
  expect_true(fs::dir_exists(configured_path))
})

test_that("duckdb_path krever gyldig dbname", {
  path <- withr::local_tempdir()
  expect_error(khtools:::duckdb_path(dbname = NULL, path = path), "dbname")
  expect_error(khtools:::duckdb_path(dbname = "", path = path), "dbname")
  expect_error(khtools:::duckdb_path(dbname = NA_character_, path = path), "dbname")
})

test_that("duckdb_opts bruker generell fallback når option ikke er satt", {
  withr::local_options(khtools.duckdbopts = NULL)
  result <- khtools:::duckdb_opts()
  expect_type(result, "list")
  expect_equal(result$mem_limit_gb, 8)
  expect_equal(fs::path_norm(result$path),
               fs::path_norm(file.path(fs::path_home(), "khtools_db")))
})

test_that("duckdb_opts bruker maskinspesifikk konfigurasjon", {
  root <- withr::local_tempdir()
  hostname <- toupper(Sys.info()[["nodename"]])
  machine_path <- file.path(root, "machine")
  config <- list(default = list(mem_limit_gb = 8, path = file.path(root, "default")))
  config[[hostname]] <- list(mem_limit_gb = 24, path = machine_path)
  withr::local_options(khtools.duckdbopts = config)
  result <- khtools:::duckdb_opts()
  expect_equal(result$mem_limit_gb, 24)
  expect_equal(fs::path_norm(result$path), fs::path_norm(machine_path))
})


test_that("duckdb_opts bruker default når maskinen ikke er konfigurert", {
  root <- withr::local_tempdir()
  default_path <- file.path(root, "default")
  
  withr::local_options(khtools.duckdbopts = list(default = list(mem_limit_gb = 6, 
                                                                path = default_path),
                                                 EN_MASKIN_SOM_IKKE_FINNES = list(mem_limit_gb = 32,
                                                                                  path = file.path(root, "other"))))
  
  result <- khtools:::duckdb_opts()
  expect_equal(result$mem_limit_gb, 6)
  expect_equal(fs::path_norm(result$path), fs::path_norm(default_path))
})

test_that("duckdb_opts bruker generell fallback når path mangler", {
  withr::local_options(khtools.duckdbopts = list(default = list(mem_limit_gb = 8, path = NULL)))
  
  result <- khtools:::duckdb_opts()
  expect_equal(result$mem_limit_gb, 8)
  expect_equal(fs::path_norm(result$path),
               fs::path_norm(file.path(fs::path_home(), "khtools_db")))
})

test_that("duckdb_init lar eksplisitt path overstyre config", {
  root <- withr::local_tempdir()
  configured_path <- file.path(root, "configured")
  explicit_path <- file.path(root, "explicit")
  withr::local_options(khtools.duckdbopts = list(
    default = list(mem_limit_gb = 8, path = configured_path)))
  
  con <- khtools::duckdb_init(dbname = "test_path_override", mem_limit_gb = 1, path = explicit_path)
  dbfile <- DBI::dbGetInfo(con)$dbname
  expect_equal(fs::path_norm(dbfile),
               fs::path_norm(file.path(explicit_path, "test_path_override.duckdb")))
  
  expect_false(fs::file_exists(file.path(configured_path, "test_path_override.duckdb")))
  khtools::duckdb_shutdown(con)
})

test_that("duckdb_init lar eksplisitt mem_limit_gb overstyre config", {
  path <- withr::local_tempdir()
  withr::local_options(khtools.duckdbopts = list(
    default = list(mem_limit_gb = 8, path = path)))
  
  con <- khtools::duckdb_init(dbname = "test_memory_override", mem_limit_gb = 1)
  
  memory_limit <- DBI::dbGetQuery(con, "SELECT current_setting('memory_limit') AS memory_limit")$memory_limit[[1L]]
  expect_match(memory_limit, "MiB|GiB|MB|GB")
  expect_false(grepl("^8(\\.0)?\\s*(GiB|GB)$",memory_limit))
  khtools::duckdb_shutdown(con)
})
