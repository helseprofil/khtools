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

#' @title duckdb_merge_tables
#' @description
#' Merger nye kolonner fra én tabell inn i en annen.
#'
#' Kolonner som finnes i begge tabeller benyttes som
#' potensielle join-kolonner. Kun kolonner angitt i
#' `join_cols` og som finnes i begge tabeller brukes
#' i join-betingelsen.
#'
#' Dersom `result = mergeto` erstattes tabellen ved hjelp
#' av en midlertidig tabell og `duckdb_replace_table()`.
#'
#' @param con db connection
#' @param mergeto tabellen som skal motta nye kolonner
#' @param mergefrom tabellen det skal merges fra
#' @param join_cols kolonner som skal brukes som join-nøkler
#' @param result resultattabell. Default er `mergeto`
#' @family duckdb
#' @export
duckdb_merge_tables <- function(con, mergeto, mergefrom, join_cols = NULL, result = NULL){
  if(is.null(result)) result <- mergeto 
  if(identical(result, mergefrom)) stop("'result' kan ikke være identisk med 'mergefrom'")
  if(is.null(join_cols)) stop("join_cols må spesifiseres. Automatisk valg av felles kolonner er ikke sikkert da verdikolonner kan finnes i begge tabeller.")
  
  if(!duckdb_table_exists(con, mergeto)) stop(sprintf("Tabell '%s' finnes ikke", mergeto))
  if(!duckdb_table_exists(con, mergefrom)) stop(sprintf("Tabell '%s' finnes ikke", mergefrom))
  
  to_cols <- duckdb_get_columns(con, mergeto)
  from_cols <- duckdb_get_columns(con, mergefrom)
  common_cols <- intersect(to_cols, from_cols)
  new_cols <- setdiff(from_cols, to_cols)
  
  valid_join_cols <- intersect(join_cols, common_cols)
  missing_join_cols <- setdiff(join_cols, common_cols)
  
  if(length(missing_join_cols)){
    stop(sprintf("Join-kolonner finnes ikke i begge tabeller: %s", paste(missing_join_cols, collapse = ", ")))
  }
  
  join_cols <- valid_join_cols
  
  if(length(new_cols) == 0L){
    msg(sprintf("- Ingen nye kolonner å merge fra %s til %s", mergefrom, mergeto))
    return(invisible(NULL))
  }
  
  if(length(join_cols) == 0L){
    msg(sprintf("- Ingen gyldige join-kolonner mellom %s og %s", mergefrom, mergeto))
    return(invisible(NULL))
  }
  
  join_cond <- paste0("org.", sql_quote_I(con, join_cols), 
                      " = new.", sql_quote_I(con, join_cols), 
                      collapse = " AND ")
  
  add_cols <- paste0("new.", sql_quote_I(con, new_cols), collapse = ", ")
  
  
  select_sql <- sprintf(
    "SELECT org.*, %s FROM %s AS org LEFT JOIN %s AS new ON %s",
    add_cols, sql_quote_I(con, mergeto), sql_quote_I(con, mergefrom), join_cond)
  
  msg(
    sprintf(
      "\n- Merger %s til %s\n-- Nye kolonner: %s\n-- Join-kolonner: %s\n-- Resultattabell: %s",
      mergefrom, mergeto, paste(new_cols, collapse = ", "), paste(join_cols, collapse = ", "), result)
  )
  
  if(identical(result, mergeto)){
    duckdb_replace_existing_table(con = con, target = result, select_sql = select_sql)
  } else {
    duckdb_drop_tables(con, result)
    invisible(
      DBI::dbExecute(con, sprintf("CREATE TABLE %s AS %s", sql_quote_I(con, result), select_sql)
      )
    )
  }
  
  actual_cols <- duckdb_get_columns(con, result)
  missing_cols <- setdiff(new_cols, actual_cols)
  if(length(missing_cols)){
    stop(sprintf("Merge feilet. Mangler kolonner i %s: %s",
                 result, paste(missing_cols, collapse = ", ")))
  }
  
  invisible(NULL)
}
