#' @keywords internal
#' @noRd
connect_access <- function(db_option){
  path <- file.path(getOption("khtools.root"), getOption(db_option))
  if(!file.exists(path)){
    stop("Finner ikke databasefilen ", path)
  }
  
  DBI::dbConnect(
    odbc::odbc(),
    .connection_string = sprintf(
      "Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=%s;",
      path
    )
  )
}

#' Koble til KHelsa-databasen
#' @keywords internal
#' @noRd
connect_khelsa <- function(){
  connect_access("khtools.db_khelsa")
}

#' Koble til geokoderdatabasen
#' @keywords internal
#' @noRd
connect_geokoder <- function(){
  connect_access("khtools.db_geo")
}
