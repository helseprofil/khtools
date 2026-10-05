#' @title msg
#' @description
#' Skriver melding til konsoll og flusher output.
#' @param ... objekter som skal skrives ut
#' @param .silent mulighet til å skru av logging ved testing
#' @family utilities
#' @export
msg <- function(..., .silent = getOption("khtools.silent", FALSE)){
  if(isTRUE(.silent)) return(invisible(NULL))
  base::cat(...)
  base::cat("\n")
  utils::flush.console()
}

#' @title header
#' @description
#' Skriver overskrift til konsoll og flusher output.
#' @param ... objekter som skal skrives ut
#' @param .silent mulighet til å skru av logging ved testing
#' @family utilities
#' @export
header <- function(..., .silent = getOption("khtools.silent", FALSE)){
  if(isTRUE(.silent)) return(invisible(NULL))
  khtools::msg("\n# --", ..., "-- #\n")
}

#' @title sql_quote_I
#' @description DBI::dbQuoteIdentifier
#' @param con db connection
#' @param x object to quote as identifier
#' @family sql
#' @export
sql_quote_I <- function(con, x){
  DBI::dbQuoteIdentifier(con, x)
}

#' @title sql_quote_S
#' @description DBI::dbQuoteString
#' @param con db connection
#' @param x object to quote as string
#' @family sql
#' @export
sql_quote_S <- function(con, x){
  DBI::dbQuoteString(con, x)
}