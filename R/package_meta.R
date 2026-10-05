#' @title load_package_options
#' @description Leser globale og pakke-spesifikke config-filer og setter options
#' @keywords internal
#' @noRd
load_package_options <- function(package, repo = "helseprofil/backend", branch = "main"){
  opts <- get_package_options(package = package, repo = repo, branch = branch)
  options(opts)
  invisible(opts)
}

#' @title get_package_options
#' @description Leser globale og pakke-spesifikke config-filer uten å sette options
#' @keywords internal
#' @noRd
get_package_options <- function(package, repo = "helseprofil/backend", branch = "main"){
  root_url <- sprintf("https://raw.githubusercontent.com/%s/%s/config/", repo, branch)
  global_url <- paste0(root_url, "config-globals.yml")
  package_url <- paste0(root_url, "config-", package, ".yml")
  global_cfg <- yaml::yaml.load_file(global_url)
  package_cfg <- tryCatch(yaml::yaml.load_file(package_url), error = function(e) list())
  cfg <- utils::modifyList(global_cfg, package_cfg)
  stats::setNames(
    as.list(cfg),
    sprintf("%s.%s", package, names(cfg))
  )
}

#' @title package_options_are_default
#' @description Sjekker om options samsvarer med configfilene
#' @keywords internal
#' @noRd
package_options_are_default <- function(package, repo = "helseprofil/backend", branch = "main"){
  expected <- get_package_options(package = package, repo = repo, branch = branch)
  current <- options()[names(expected)]
  isTRUE(all.equal(expected, current))
}

#' @title package_update_available
#' @description Sjekker om en nyere versjon finnes på GitHub
#' @keywords internal
#' @noRd
package_update_available <- function(package, branch = "main", owner = "helseprofil"){
  installed_version <- utils::packageDescription(package)[["Version"]]
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