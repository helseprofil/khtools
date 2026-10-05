#' @title set_option_dim_tab
#' @description
#' Genererer en liste over alle unike verdier i ACCESS::TAB1-3
#' Brukes som oppslag for å identifisere dimensjonskolonner
#' @family options
#' @keywords internal
#' @noRd
set_option_dim_tab <- function(){
  tabs <- get_all_tabdims()
  options(khtools.dim.tab = tabs)
  invisible(tabs)
}

#' @keywords internal
#' @noRd
get_all_tabdims <- function(){
  con <- connect_khelsa()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  date <- format(Sys.Date(), "%Y-%m-%d")
  tabs <- data.table::as.data.table(
    DBI::dbGetQuery(con, sprintf(
    "SELECT TAB1, TAB2, TAB3 FROM FILGRUPPER 
    WHERE VERSJONFRA <= #%s# AND VERSJONTIL > #%s#",
    date, date)))
  tabs <- data.table::melt(tabs, measure.vars = c("TAB1", "TAB2", "TAB3"))[!is.na(value), unique(value)]
  sort(tabs)
}