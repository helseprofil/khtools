#' @title get_config_options
#' @description
#' Leser én eller flere YAML-filer fra GitHub og returnerer et samlet,
#' navngitt sett med options.
#'
#' Hver configfil får sitt angitte prefix. Configfilene behandles i den
#' rekkefølgen de er oppgitt. Dersom flere filer gir samme ferdige
#' optionnavn, overskriver den siste filen tidligere verdier.
#'
#' Dynamiske options kan legges til med argumentet `dynamic_options`.
#' Hvert element skal være en funksjon uten argumenter. Funksjonen kjøres
#' hver gang options leses, og resultatet lagres under elementets navn.
#'
#' @param config_files Navngitt tegnvektor. Verdiene er configfilnavn og
#'   navnene er prefixene som skal brukes.
#' @param dynamic_options Navngitt liste med funksjoner uten argumenter.
#' @param repo GitHub-repository på formatet "owner/repository".
#' @param branch Branch i GitHub-repository.
#'
#' @return Navngitt liste med ferdige optionnavn og verdier.
#'
#' @examples
#' \dontrun{
#' get_config_options(
#'   config_files = c(
#'     khfunctions = "config-globals.yml",
#'     khfunctions = "config-khfunctions.yml",
#'     kh = "config-architecture.yml"
#'   )
#' )
#' }
#'
#' @keywords internal
#' @noRd
get_config_options <- function(config_files, dynamic_options = list(), 
                               repo = "helseprofil/backend", branch = "main"){
  
  if(!is.character(config_files) || !length(config_files) ||
     is.null(names(config_files)) || any(!nzchar(names(config_files))) || 
     any(!nzchar(config_files))) {
    stop("'config_files' må være en navngitt tegnvektor der navnene er prefix og verdiene er configfilnavn.",
         call. = FALSE)
  }
  
  if(length(dynamic_options) &&
    (is.null(names(dynamic_options)) || 
     any(!nzchar(names(dynamic_options))) || 
     !all(vapply(dynamic_options, is.function, logical(1L))))
    ){
    stop("'dynamic_options' må være en navngitt liste med funksjoner.", call. = FALSE)
  }
  
  root_url <- sprintf("https://raw.githubusercontent.com/%s/%s/config/", repo, branch)
  opts <- list()
  
  for (i in seq_along(config_files)) {
    prefix <- names(config_files)[[i]]
    config_file <- config_files[[i]]
    config_url <- paste0(root_url, config_file)
    
    config <- tryCatch(yaml::yaml.load_file(config_url),
                       error = function(e) stop("Kunne ikke lese configfilen fra GitHub: ", 
                                                config_url, "\n", conditionMessage(e), call. = FALSE))
    
    if(is.null(config)) next
    
    if(!is.list(config)) stop("Configfilen må inneholde en navngitt YAML-liste: ",
                               config_url, call. = FALSE)
    
    if(is.null(names(config)) || any(!nzchar(names(config)))) stop("Configfilen inneholder verdier uten navn: ",
                                                                   config_url, call. = FALSE)
    
    if("paths" %in% names(config)) {
      config$paths <- build_paths(config$paths)
    }
    
    if(length(config)) {
      option_names <- paste(prefix, names(config), sep = ".")
      names(config) <- option_names
      opts[option_names] <- config
    }
  }
  
  for(option_name in names(dynamic_options)) {
    opts[[option_name]] <- dynamic_options[[option_name]]()
  }
  
  opts
}

build_paths <- function(paths, parent = NULL) {
  
  current_root <- parent
  if(!is.null(paths$root)){
    current_root <- if(is.null(parent)) {
      paths$root
    } else {
      file.path(parent, paths$root)
    }
    paths$root <- current_root
  }
  
  for(path_name in setdiff(names(paths), "root")) {
    
    if(is.list(paths[[path_name]])) {
      paths[[path_name]] <- build_paths(
        paths[[path_name]],
        parent = current_root
      )
    } else {
      paths[[path_name]] <- file.path(
        current_root,
        paths[[path_name]]
      )
    }
  }
  
  paths
}

#' @title load_package_options
#' @description
#' Leser options fra GitHub og setter dem i aktiv R-sesjon.
#'
#' Som standard settes bare options som ikke finnes fra før. Dette gjør
#' at options kan overstyres per sesjon før en pakke lastes, samtidig som
#' alle manglende options initialiseres.
#'
#' Med `overwrite = TRUE` resettes alle aktuelle options til ferske verdier
#' fra GitHub.
#'
#' @inheritParams get_config_options
#' @param overwrite Skal eksisterende options overskrives?
#' @return Usynlig navngitt liste med fasitverdiene som ble lest.
#'
#' @keywords internal
#' @noRd
load_package_options <- function(config_files = NULL,
                                 package = NULL,
                                 dynamic_options = list(), 
                                 repo = "helseprofil/backend", 
                                 branch = "main", 
                                 overwrite = FALSE){
  
  if(is.null(config_files) == is.null(package)) {
    stop("Angi enten 'config_files' eller 'package', men ikke begge.", call. = FALSE)
  }
  
  if (!is.null(package)){
    architecture_options <- get_config_options(config_files = c(kh = "config-arkitektur.yml"),
                                               repo = repo,
                                               branch = branch)
    architecture_options[["kh.dim.tab"]] <- get_all_tabdims(architecture_options[["kh.paths"]]$database$khelsa)
    package_opts <- architecture_options[["kh.package_opts"]][[package]]
    package_options <- list()
    
    if(length(package_opts)){
      package_config_files <- stats::setNames(package_opts, rep(package, length(package_opts)))
      package_options <- get_config_options(config_files = package_config_files,
                                            repo = repo,
                                            branch = branch)
    }
    
    for(option_name in names(dynamic_options)) {
      package_options[[option_name]] <- dynamic_options[[option_name]]()
    }
    
    options(architecture_options)
    
    if(isTRUE(overwrite)){
      options(package_options)
    } else {
      missing_option_names <- setdiff(names(package_options), names(options()))
      if(length(missing_option_names)) options(package_options[missing_option_names])
    }
    opts <- c(architecture_options, package_options)
    return(invisible(opts))
  }
    
  opts <- get_config_options(config_files = config_files,
                             dynamic_options = dynamic_options,
                             repo = repo,
                             branch = branch)

  if(isTRUE(overwrite)) {
    options(opts)
    return(invisible(opts))
  }
  
  missing_option_names <- setdiff(names(opts),names(options()))
  if(length(missing_option_names)) options(opts[missing_option_names])

  invisible(opts)
}

#' @title package_options_are_default
#' @description
#' Leser ferske standardoptions for en KH-pakke og sammenligner dem
#' med options som er satt i aktiv R-sesjon.
#'
#' Felles KH-arkitektur leses fra config-arkitektur.yml.
#' Dynamisk `kh.dim.tab` leses fra KHELSA.
#' Eventuelle pakkeconfigfiler hentes fra `kh.package_opts`.
#' Eventuelle dynamiske pakkeoptions genereres på nytt.
#'
#' @param package Pakkenavn.
#' @param dynamic_options Navngitt liste med funksjoner uten argumenter.
#' @param repo GitHub-repository på formatet "owner/repository".
#' @param branch Branch i GitHub-repository.
#'
#' @return En logisk verdi. `TRUE` dersom aktive options er identiske
#'   med ferske defaults, ellers `FALSE`.
#'
#' @keywords internal
#' @noRd
package_options_are_default <- function(package, 
                                        dynamic_options = list(),
                                        repo = "helseprofil/backend",
                                        branch = "main"){
  
  default_options <- get_config_options(config_files = c(kh = "config-arkitektur.yml"), 
                                        repo = repo, branch = branch)
  default_options[["kh.dim.tab"]] <- get_all_tabdims(default_options[["kh.paths"]]$database$khelsa)
  package_opts <- default_options[["kh.package_opts"]][[package]]
  
  if(length(package_opts)){
    package_config_files <- stats::setNames(package_opts, rep(package, length(package_opts)))
    package_options <- get_config_options(config_files = package_config_files,
                                          repo = repo, branch = branch)
    default_options <- c(default_options, package_options)
  }
  
  for(option_name in names(dynamic_options)) {
    default_options[[option_name]] <- dynamic_options[[option_name]]()
  }
  
  current_options <- options()[names(default_options)]
  
  identical(current_options, default_options)
}

#' @title package_update_available
#' @description Sjekker om en nyere versjon finnes på GitHub
#' @keywords internal
#' @noRd
package_update_available <- function(package, branch = "main", owner = "helseprofil"){
  description <- suppressWarnings(utils::packageDescription(package))
  if(length(description) == 1L && is.na(description)) return(FALSE)
  
  installed_version <- description[["Version"]]
  if(is.null(installed_version)) return(FALSE)
  desc_url <- sprintf("https://raw.githubusercontent.com/%s/%s/%s/DESCRIPTION", owner, package, branch)
  
  txt <- tryCatch(readLines(desc_url, warn = FALSE), error = function(e) NULL)
  if(is.null(txt)) return(FALSE)
  github_version <- sub("^Version:[[:space:]]*","",grep("^Version:", txt, value = TRUE))
  if(length(github_version) != 1L) return(FALSE)
  numeric_version(github_version) > numeric_version(installed_version)
}

#' @title check_package_update
#' @description Gir brukeren anledning til å oppdatere pakker dersom ny versjon foreligger
#' @keywords internal
#' @noRd
check_package_update <- function(package, branch = "main", owner = "helseprofil") {
  
  if(interactive() && 
     package_update_available(package = package, branch = branch, owner = owner)){
    
    x <- utils::menu(title = sprintf("Update %s now?", package),
                     choices = c("Yes", "No")
                     )
    
    if(x == 1){
      packageStartupMessage(
        "Please restart your R session and then run:"
      )
      packageStartupMessage(
        sprintf('remotes::install_github("%s/%s@%s")',
                owner, package, branch))
    }
  }
  
  invisible()
}