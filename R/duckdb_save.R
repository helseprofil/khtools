#' @title duckdb_save_file
#' @description
#' Eksporterer en tabell eller et SQL-uttrykk fra DuckDB til fil.
#'
#' Wrapper rundt DuckDB COPY ... TO.
#'
#' @param con db connection
#' @param source tabellnavn eller SQL-uttrykk
#' @param filepath filsti
#' @family duckdb
#' @export
duckdb_save_file <- function(con, source, filepath){
  
  format <- tolower(tools::file_ext(filepath))
  format <- match.arg(format, c("parquet", "csv"))
  
  export_options <- switch(
    format,
    parquet = "
      FORMAT PARQUET,
      COMPRESSION ZSTD,
      ROW_GROUP_SIZE 1000000
    ",
    csv = "
      HEADER,
      DELIMITER ';'
    "
  )
  
  invisible(
    DBI::dbExecute(
      con,
      sprintf(
        "COPY %s TO %s (%s)",
        source,
        sql_quote_S(con, filepath),
        export_options
      )
    )
  )
  
  invisible(NULL)
}