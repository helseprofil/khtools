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

#' @title read_pq
#' @description
#' Wrapper rundt data.table::setDT(arrow::read_parquet(...)). 
#' Leser en parquet-fil inn i minnet og konverterer til data.table
#' @param path filsti til parquetfilen
#' @export
read_pq <- function(path){
  if(!grepl("\\.parquet$", path)) stop("path går ikke til en .parquet-fil")
  if(!file.exists(path)) stop("Filen finnes ikke, eller kan ikke leses")
  data.table::setDT(arrow::read_parquet(path))
}

#' @title convert_spss_to_parquet
#' @description Leser en SPSS-fil og lagrer en parquetfil i samme mappe.
#' @param orgpath sti til originalfil
#' @param newname filnavn den nye parquetfilen skal få
#' @export
convert_spss_to_parquet <- function(orgpath, newname){
  file <-try(foreign::read.spss(file = orgpath, use.value.labels = FALSE, max.value.labels = 0, as.data.frame = T), silent = T)
  if(inherits(file, "try-error")) stop("Error when reading file: ", orgpath)
  data.table::setDT(file)
  
  cols <- names(file)
  empty <- cols == ""
  if(any(empty)){
    cols[empty] <- paste0("C", which(empty))
    data.table::setnames(dt, cols)
  }
  
  if(!grepl(".parquet$", newname)) newname <- paste0(newname, ".parquet")
  dir <- dirname(orgpath)
  newpath <- file.path(dir, newname)
  arrow::write_parquet(file, newpath)
}
