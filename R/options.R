#' @keywords internal
#' @noRd
get_all_tabdims <- function(path){
  con <- connect_access(path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  date <- format(Sys.Date(), "%Y-%m-%d")
  tabs <- data.table::as.data.table(
    DBI::dbGetQuery(con, sprintf(
    "SELECT TAB1, TAB2, TAB3 FROM FILGRUPPER 
    WHERE VERSJONFRA <= #%s# AND VERSJONTIL > #%s#",
    date, date)))
  tabs <- data.table::melt(tabs, measure.vars = c("TAB1", "TAB2", "TAB3"))[["value"]]
  tabs <- unique(tabs[!is.na(tabs)])
  sort(c(tabs, "TAB1", "TAB2", "TAB3"))
}