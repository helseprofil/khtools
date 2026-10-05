.onLoad <- function(libname, pkgname){
  load_package_options("khtools")
  try(set_option_dim_tab(), silent = TRUE)
  invisible()
}