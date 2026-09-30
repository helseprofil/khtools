# Opprette, rense og stenge/fjerne ----

#' @title duckdb_init
#' @description 
#' Oppretter en arbeidsdatabase med en satt grense for RAM-bruk og sørger for at denne er tom
#' Oppretter også en temp-database for eventuelt spilling til disk
#' @param dbname name of the duckdb-file
#' @param mem_limit_gb grense for hvor mange GB RAM databasen får lov å benytte
#' @return en databaseconnection
#' @family duckdb
#' @export
duckdb_init <- function(dbname = NULL, mem_limit_gb = 8){
  if(is.null(dbname)) stop("du må gi databasen et navn ved å sette dbname")
  duckdir <- file.path(fs::path_home(), "helseprofil", "duck")
  fs::dir_create(duckdir)
  db <- file.path(duckdir, paste0(dbname, ".duckdb"))
  
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE), dbdir = db)
  invisible(DBI::dbExecute(con, 
                           sprintf("SET memory_limit = '%sGB'", 
                                   mem_limit_gb)))
  
  temp_dir <- file.path(tempdir(), "duckdb", "temp")
  fs::dir_create(temp_dir)
  DBI::dbExecute(con, sprintf("SET temp_directory='%s'", gsub("\\\\", "/", temp_dir)))
  
  tabs <- duckdb_get_tables(con = con)
  for(i in seq_along(tabs)){
    invisible(DBI::dbExecute(con, paste0("DROP TABLE IF EXISTS ", tabs[[i]], " CASCADE;")))
  }
  con
}

#' @title duckdb_clean
#' @description Frigjør minne i databasen, nyttig etter store skriveoperasjoner
#' @param con db connection
#' @family duckdb
#' @export
duckdb_clean <- function(con){
  if (DBI::dbIsValid(con)) {
    invisible(try(DBI::dbExecute(con, "CHECKPOINT"), silent = TRUE))
    invisible(try(DBI::dbExecute(con, "VACUUM"), silent = TRUE))
  }
  invisible(NULL)
}

#' @title duckdb_shutdown
#' @description
#' Kobler fra en DuckDB-database og sletter databasefilen.
#' @param con db connection
#' @family duckdb
#' @export
duckdb_shutdown <- function(con){
  if(is.null(con) || !DBI::dbIsValid(con)) return(invisible(NULL))
  dbfile <- DBI::dbGetInfo(con)$dbname
  DBI::dbDisconnect(con, shutdown = TRUE)
  files <- c(dbfile, paste0(dbfile, ".wal"))
  files <- files[file.exists(files)]
  if(length(files) > 0) fs::file_delete(files)
  invisible(NULL)
}


