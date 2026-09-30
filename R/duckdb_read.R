#' @title duckdb_table_exists
#' @description Sjekker at tabell eksisterer
#' @param con db connection
#' @param tablename navnet på tabellen du skal sjekke
#' @family duckdb
#' @export
duckdb_table_exists <- function(con, tablename = NULL){
  if(
    is.null(tablename) ||
    is.na(tablename) ||
    !nzchar(tablename)
  ){
    return(FALSE)
  }
  DBI::dbIsValid(con) && DBI::dbExistsTable(con, tablename)
}

#' @title duckdb_get_columns
#' @description DBI::dbListFields
#' @param con db connection
#' @param tablename navnet på tabellen du skal sjekke
#' @family duckdb
#' @export
duckdb_get_columns <- function(con, tablename){
  DBI::dbListFields(con, tablename)
}

#' @title duckdb_get_tables
#' @description DBI::dbListTables
#' @param con db connection
#' @family duckdb
#' @export
duckdb_get_tables <- function(con){
  DBI::dbListTables(con = con)
}

#' @title duckdb_fetch_table
#' @description fetch table from duckdb
#' @returns data.table object
#' @param con db connection
#' @param tablename navnet på tabellen du skal sjekke
#' @param limit antall rader du vil lese (f.eks. limit = 10 for å bare lese øverste 10 rader)
#' @family duckdb
#' @export
duckdb_fetch_table <- function(con, tablename, limit = NULL){
  exist <- duckdb_table_exists(con, tablename)
  if(!exist) stop(tablename, " finnes ikke i duckdb")
  
  sql <- if(is.null(limit)){
    sprintf("SELECT * FROM %s", sql_quote_I(con, tablename))
  } else {
    sprintf("SELECT * FROM %s LIMIT %s", sql_quote_I(con, tablename), as.integer(limit))
  }
  
  dt <- DBI::dbGetQuery(con, sql)
  data.table::setDT(dt)
  dt[]
}
