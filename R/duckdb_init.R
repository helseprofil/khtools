# Opprette, rense og stenge/fjerne ----

#' @title duckdb_init
#' @description 
#' Oppretter en arbeidsdatabase med en satt grense for RAM-bruk og sørger for at denne er tom
#' Oppretter også en temp-database for eventuelt spilling til disk
#' Default path og mem_limit_gb styres i config-filen, men kan overstyres av bruker. 
#' @param dbname name of the duckdb-file
#' @param mem_limit_gb grense for hvor mange GB RAM databasen får lov å benytte
#' @param path valgfritt: filsti til hvor databasen skal ligge
#' @return en databaseconnection
#' @family duckdb
#' @export
duckdb_init <- function(dbname = NULL, path = NULL, mem_limit_gb = NULL){
  if(is.null(mem_limit_gb)) mem_limit_gb <- duckdb_opts()$mem_limit_gb
  db <- duckdb_path(dbname = dbname, path = path)
  duckdir <- dirname(db)
  
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE), dbdir = db)
  invisible(DBI::dbExecute(con, sprintf("SET memory_limit = '%sGB'", mem_limit_gb)))
  
  temp_dir <- file.path(duckdir, "temp")
  if(fs::dir_exists(temp_dir)) fs::dir_delete(temp_dir)
  fs::dir_create(temp_dir)
  DBI::dbExecute(con, sprintf("SET temp_directory = %s", 
                              sql_quote_S(con, temp_dir)))
  
  tabs <- duckdb_get_tables(con = con)
  for(i in seq_along(tabs)){
    invisible(DBI::dbExecute(con, sprintf("DROP TABLE IF EXISTS %s CASCADE", 
                                         sql_quote_I(con, tabs[[i]]))))
  }
  con
}

#' @title duckdb_clean
#' @description Frigjør minne i databasen, nyttig etter store skriveoperasjoner
#' @param con db connection
#' @family duckdb
#' @export
duckdb_clean <- function(con){
  if(is.null(con) || !DBI::dbIsValid(con)) return(invisible(NULL))
  if(DBI::dbIsValid(con)) {
    invisible(try(DBI::dbExecute(con, "CHECKPOINT"), silent = TRUE))
    invisible(try(DBI::dbExecute(con, "VACUUM"), silent = TRUE))
  }
  invisible(NULL)
}

#' @title duckdb_connect
#' @description
#' Kobler til en eksisterende arbeidsdatabase.
#'
#' Databasens standardplassering og standardgrense for RAM-bruk styres
#' av `khtools.duckdbopts`, men kan overstyres med `path` og
#' `mem_limit_gb`.
#'
#' Funksjonen oppretter ikke en ny database. Dersom databasefilen ikke
#' finnes, stoppes kjøringen med en feilmelding.
#' @inheritParams duckdb_init dbname mem_limit_gb path
#' @return en databaseconnection
#' @family duckdb
#' @export
duckdb_connect <- function(dbname = NULL, path = NULL, mem_limit_gb = NULL) {
  if (is.null(mem_limit_gb)) mem_limit_gb <- duckdb_opts()$mem_limit_gb
  db <- duckdb_path(dbname = dbname, path = path)
  if(!fs::file_exists(db)) {
    stop(sprintf(
        "DuckDB-databasen finnes ikke: %s. Databasen m\u00e5 f\u00f8rst opprettes med khtools::duckdb_init().",
        db), call. = FALSE)
    }
  
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE), dbdir = db)
  connected <- FALSE
  on.exit({
    if (!connected && DBI::dbIsValid(con)) {
      DBI::dbDisconnect(con, shutdown = TRUE)
    }
  }, add = TRUE)
  
  invisible(
    DBI::dbExecute(con, sprintf("SET memory_limit = '%sGB'", mem_limit_gb))
  )
  
  temp_dir <- file.path(dirname(db), "temp")
  fs::dir_create(temp_dir)
  invisible(DBI::dbExecute(con, sprintf("SET temp_directory = %s",
                                        sql_quote_S(con, temp_dir))))
  
  connected <- TRUE
  con
}

#' @title duckdb_disconnect
#' @description
#' Kobler fra en DuckDB-database uten å slette databasefilen eller
#' tempmappen.
#'
#' Bruk `duckdb_disconnect()` når databasen skal kunne åpnes igjen med
#' `duckdb_connect()`. Bruk `duckdb_shutdown()` når databasefilen og
#' tempmappen også skal slettes.
#'
#' @param con db connection
#' @return usynlig `NULL`
#' @family duckdb
#' @export
duckdb_disconnect <- function(con) {
  if (is.null(con) || !DBI::dbIsValid(con)) return(invisible(NULL))
  DBI::dbDisconnect(con, shutdown = TRUE)
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
  temp_dir <- tryCatch(
    DBI::dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")$temp_directory,
    error = function(e) NULL
  )
  
  DBI::dbDisconnect(con, shutdown = TRUE)
  files <- c(dbfile, paste0(dbfile, ".wal"))
  files <- files[file.exists(files)]
  if(length(files) > 0) fs::file_delete(files)
  if(!is.null(temp_dir) && fs::dir_exists(temp_dir)) {
    fs::dir_delete(temp_dir)
  }
  invisible(NULL)
}


# Helpers ----
#' @title duckdb_opts
#' @description Leser fra config-filen og setter path og mem_limit basert på maskinen man jobber på
#' @family duckdb
#' @keywords internal
duckdb_opts <- function(){
  config <- getOption("khtools.duckdbopts")
  if(is.null(config)){
    return(list(mem_limit_gb = 8,
                path = file.path(fs::path_home(), "khtools_db")))
  }
  hostname <- toupper(Sys.info()[["nodename"]])
  machine_config <- config[[hostname]]
  
  if(is.null(machine_config)) machine_config <- config$default
  if(is.null(machine_config$path)) machine_config$path <- file.path(fs::path_home(), "khtools_db")
  machine_config
}

#' Dersom `path` ikke er angitt, brukes maskinens standardplassering
#' fra `khtools.duckdbopts`.
#' @inheritParams duckdb_init dbname path
#' @return full filsti til databasefilen
#' @family duckdb
#' @keywords internal
duckdb_path <- function(dbname, path = NULL){
  if(is.null(dbname) || length(dbname) != 1L || is.na(dbname) || !nzchar(dbname)){
    stop("Du m\u00e5 gi databasen et navn ved \u00e5 sette dbname", call. = FALSE)
  }
  
  if(!is.null(path) && (length(path) != 1L || is.na(path) || !nzchar(path))){
    stop("'path' m\u00e5 v\u00e6re en (1) gyldig filsti.", call. = FALSE)
  }
  
  if(is.null(path)) path <- duckdb_opts()$path
  fs::dir_create(path)
  file.path(path, paste0(dbname, ".duckdb"))
}

