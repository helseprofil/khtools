khtools_config_files <- c(khtools = "config-khtools.yml")

.onLoad <- function(libname, pkgname) {
  
  config_load_package_options(config_files = khtools_config_files,
                       repo = "helseprofil/backend",
                       branch = "main",
                       overwrite = TRUE)
  invisible(NULL)
}

.onAttach <- function(libname, pkgname) {
  
  config_check_package_update(package = "khtools", branch = "main")
  packageStartupMessage("khtools version: ", utils::packageVersion("khtools"))
  invisible(NULL)
}
