#' @title duckdb_write_table
#' @description Skriv eller overskriv eksisterende tabell i duckdb
#' @param con db connection
#' @param tablename navn på tabellen du skal skrive
#' @param data datasett som skal skrives
#' @param temp er det en midlertidig tabell, default = TRUE
#' @param overwrite oveskrive dersom tabellen eksisterer, default = TRUE
#' @param ... andre argumenter som aksepteres av DBI::dbWriteTable, som field.types for å spesifisere kolonnetype
#' @family duckdb
#' @export
duckdb_write_table <- function(con, tablename, data, temp = TRUE, overwrite = TRUE, ...){
  DBI::dbWriteTable(
    conn = con,
    name = tablename,
    value = data,
    overwrite = overwrite,
    temporary = temp,
    ...
  )
  invisible(NULL)
}

#' @title duckdb_drop_tables
#' @description drops tables if they exist
#' @param con db connection
#' @param tables liste over tabeller som skal droppes
#' @family duckdb
#' @export
duckdb_drop_tables <- function(con, tables){
  tables <- sql_quote_I(con, tables)
  sql <- paste(
    sprintf("DROP TABLE IF EXISTS %s", tables),
    collapse = ";\n"
  )
  invisible(DBI::dbExecute(con, sql))
}

#' @title replace_table_duckdb
#' @description
#' Erstatter en tabell med en annen i duckdb. Ved bearbeiding av en tabell kan resultatet
#' skrives til en tmp-tabell, og så kan hovedtabellen erstattes med denne etterpå. Da slipper
#' vi å overskrive tabellen med seg selv som kan være ustabilt. 
#' Vi kan i stedet bruke CREATE TABLE tmp AS SELECT * FROM TABELL, og deretter bruke 
#' replace_table_duckdb(con, target = TABELL, source = tmp). Dette vil først generere ny tabell
#' tmp, og deretter erstatte originaltabellen med denne. 
#' @param con db connection
#' @param target navn på tabellen man skal sitte igjen med
#' @param source navn på tabellen som skal ende opp som target
#' @family duckdb
#' @export
duckdb_replace_table <- function(con, target, source){
  
  if(identical(target, source)) stop("'target' og 'source' kan ikke være samme tabell")
  stopifnot(duckdb_table_exists(con, target))
  stopifnot(duckdb_table_exists(con, source))
  
  backup <- paste0(target, "__replace__table__backup")
  on.exit(duckdb_drop_tables(con, backup), add = TRUE)
  duckdb_drop_tables(con, backup)
  
  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, sprintf("ALTER TABLE %s RENAME TO %s", sql_quote_I(con, target), sql_quote_I(con, backup)))
    DBI::dbExecute(con, sprintf("ALTER TABLE %s RENAME TO %s", sql_quote_I(con, source), sql_quote_I(con, target)))
  })
  invisible(NULL)
}

#' @title duckdb_write_and_replace_table
#' @description
#' Skriver data til en midlertidig tabell og erstatter deretter
#' måltabellen atomisk ved hjelp av duckdb_replace_table().
#' Dette er nyttig når en tabell er generert i R, eller lest ut av DuckDB, bearbeidet i R,
#' og skal skrives tilbake uten å overskrive tabellen med seg selv som kan være ustabilt.
#'
#' @param con db connection
#' @param table tabellen som skal erstattes
#' @param data data.frame eller data.table som skal skrives
#' @param temporary om tmp-tabellen skal være temporary
#' @family duckdb
#' @export
duckdb_write_and_replace_table_from_R <- function(con, table, data, temporary = TRUE){
  tmp_table <- sprintf("%s___tmp_result", table)
  duckdb_drop_tables(con, tmp_table)
  duckdb_write_table(
    con = con,
    tablename = tmp_table,
    data = data,
    temp = temporary,
    overwrite = TRUE
  )
  
  duckdb_replace_table(
    con = con,
    target = table,
    source = tmp_table
  )
  
  invisible(NULL)
}

#' @title duckdb_create_and_replace_table
#' @description
#' Erstatter CREATE OR REPLACE X AS SELECT FROM X, ved at det først
#' skrives en tmp_tabell, som deretter overskriver måltabellen. 
#'
#' @param con db connection
#' @param target navn på måltabell
#' @param select_sql uttrykk som genererer den nye tabellen
#' @family duckdb
#' @export
duckdb_create_and_replace_table <- function(con, target, select_sql){
  tmp_table <- sprintf("%s___tmp_result", target)
  duckdb_drop_tables(con, tmp_table)
  
  invisible(
    DBI::dbExecute(
      con,
      sprintf(
        "CREATE TABLE %s AS %s",
        sql_quote_I(con, tmp_table),
        select_sql
      )
    )
  )
  
  duckdb_replace_table(con = con, target = target, source = tmp_table)
  invisible(NULL)
}
