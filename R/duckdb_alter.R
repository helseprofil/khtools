#' @title duckdb_ensure_columns
#' @description Sikrer at kolonner eksisterer, eller oppretter dem som tomme kolonner med riktig type.
#' @param con db connection
#' @param table table name
#' @param cols navngitt vektor eller liste på formatet c(KOL = "TYPE", KOL2 = "TYPE") eller list(KOL = ...)
#' @family duckdb
#' @export
duckdb_ensure_columns <- function(con, table, cols){
  if(is.null(names(cols))) stop("cols må være navngitt")
  types <- as.character(unlist(cols, use.names = FALSE))
  
  sql <- paste(
    sprintf(
      "ALTER TABLE %s ADD COLUMN IF NOT EXISTS %s %s",
      sql_quote_I(con, table), 
      sql_quote_I(con, names(cols)), 
      types), 
    collapse = ";\n")
  
  sql <- paste0(sql, ";")
  invisible(DBI::dbExecute(con, sql))
}
