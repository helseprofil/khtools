#' @title connect_access
#' @description Kobler til en microsoft access-database
#' @param path filsti til hvor databasen ligger
#' @returns access connection
#' @export
connect_access <- function(path){
  if (is.null(path)) {
    stop("Path er ikke satt.", call. = FALSE)
  }
  
  if (!file.exists(path)) {
    stop("Finner ikke databasefilen ", path, call. = FALSE)
  }
  
  DBI::dbConnect(odbc::odbc(), 
                 .connection_string = sprintf("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s;", path)
  )
}
