local_test_duckdb <- function() {
  dbname <- sprintf("test_%s", paste(sample(c(letters, 0:9), 12, TRUE),collapse = ""))
  path <- withr::local_tempdir(.local_envir = parent.frame())
  con <- duckdb_init(dbname = dbname, mem_limit_gb = 1, path = path)
  withr::defer(duckdb_shutdown(con), parent.frame())
  con
}

silent_test <- function(){
  withr::local_options(list(khtools.silent = TRUE),
                       .local_envir = parent.frame())
}
