local_test_duckdb <- function(){
  dbname <- sprintf( 
    "test_%s",
    paste(sample(c(letters, 0:9), 12, TRUE), collapse = "")
  )
  
  con <- duckdb_init(dbname)
  
  withr::defer(
    duckdb_shutdown(con),
    parent.frame()
  )
  
  con
}

silent_test <- function(){
  withr::local_options(list(khtools.silent = TRUE),
                       .local_envir = parent.frame())
}
