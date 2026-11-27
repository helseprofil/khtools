# config_get_options -------------------------------------------------------

test_that("config_get_options slår sammen global og pakkespesifikk config", {
  mock_yaml <- function(path) {
    if(grepl("config-globals.yml$", path)) {
      return(list(year = 2026, root = "O:/", db = "test.accdb"))
    }
    
    if(grepl("config-khfunctions.yml$", path)) {
      return(list(db = "kh.accdb", illegal = "abc"))
    }
    stop("unexpected file")
  }
  
  mockery::stub(
    config_get_options,
    "yaml::yaml.load_file",
    mock_yaml
  )
  
  opts <- config_get_options(
    config_files = c(
      khfunctions = "config-globals.yml",
      khfunctions = "config-khfunctions.yml"
    )
  )
  
  testthat::expect_identical(
    opts,
    list(
      khfunctions.year = 2026,
      khfunctions.root = "O:/",
      khfunctions.db = "kh.accdb",
      khfunctions.illegal = "abc"
    )
  )
})

test_that("senere configfiler overskriver tidligere configfiler", {
  mock_yaml <- function(path) {
    if (grepl("config-globals.yml$", path)) {
      return(
        list(
          year = 2026,
          db = "global.accdb"
        )
      )
    }
    
    if (grepl("config-khfunctions.yml$", path)) {
      return(
        list(
          db = "package.accdb"
        )
      )
    }
    
    stop("unexpected file")
  }
  
  mockery::stub(
    config_get_options,
    "yaml::yaml.load_file",
    mock_yaml
  )
  
  opts <- config_get_options(
    config_files = c(
      khfunctions = "config-globals.yml",
      khfunctions = "config-khfunctions.yml"
    )
  )
  
  testthat::expect_identical(
    opts$khfunctions.db,
    "package.accdb"
  )
  
  testthat::expect_identical(
    opts$khfunctions.year,
    2026
  )
})


test_that("config_get_options legger til dynamiske options", {
  mockery::stub(
    config_get_options,
    "yaml::yaml.load_file",
    function(path) {
      list(year = 2026)
    }
  )
  
  opts <- config_get_options(
    config_files = c(
      khfunctions = "config-khfunctions.yml"
    ),
    dynamic_options = list(
      "khfunctions.snutter" = function() {
        c("snutt_a", "snutt_b")
      }
    )
  )
  
  testthat::expect_identical(
    opts$khfunctions.year,
    2026
  )
  
  testthat::expect_identical(
    opts$khfunctions.snutter,
    c("snutt_a", "snutt_b")
  )
})


test_that("config_get_options avviser config_files uten prefix", {
  testthat::expect_error(
    config_get_options(
      config_files = "config-khfunctions.yml"
    ),
    "'config_files' må være en navngitt tegnvektor",
    fixed = TRUE
  )
})


test_that("config_get_options gir feil når en configfil ikke kan leses", {
  mockery::stub(
    config_get_options,
    "yaml::yaml.load_file",
    function(path) {
      stop("file not found")
    }
  )
  
  testthat::expect_error(
    config_get_options(
      config_files = c(
        khfunctions = "config-khfunctions.yml"
      )
    ),
    "Kunne ikke lese configfilen fra GitHub",
    fixed = TRUE
  )
})


# config_load_package_options ---------------------------------------------

test_that("config_load_package_options setter arkitektur og pakkeoptions", {
  withr::local_options(
    list(
      kh.paths = NULL,
      kh.package_opts = NULL,
      kh.dim.tab = NULL,
      khfunctions.year = NULL,
      khfunctions.root = NULL
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(
        list(
          kh.paths = list(
            database = list(
              khelsa = "test.accdb"
            )
          ),
          kh.package_opts = list(
            khfunctions = c(
              "config-globals.yml",
              "config-khfunctions.yml"
            )
          )
        )
      )
    }
    
    list(
      khfunctions.year = 2026,
      khfunctions.root = "O:/"
    )
  }
  
  mock_get_all_tabdims <- mockery::mock(
    c("AAR", "ALDER", "GEO")
  )
  
  mockery::stub(
    config_load_package_options,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_load_package_options,
    "get_all_tabdims",
    mock_get_all_tabdims
  )
  
  ret <- config_load_package_options(
    package = "khfunctions",
    overwrite = TRUE
  )
  
  testthat::expect_identical(
    getOption("khfunctions.year"),
    2026
  )
  
  testthat::expect_identical(
    getOption("khfunctions.root"),
    "O:/"
  )
  
  testthat::expect_identical(
    getOption("kh.dim.tab"),
    c("AAR", "ALDER", "GEO")
  )
  
  testthat::expect_identical(
    ret$khfunctions.year,
    2026
  )
  
  testthat::expect_identical(
    ret$khfunctions.root,
    "O:/"
  )
  
  testthat::expect_identical(
    ret$kh.dim.tab,
    c("AAR", "ALDER", "GEO")
  )
  
  mockery::expect_called(
    mock_get_all_tabdims,
    1
  )
  
  tabdim_args <- mockery::mock_args(
    mock_get_all_tabdims
  )[[1L]]
  
  testthat::expect_identical(
    tabdim_args[[1L]],
    "test.accdb"
  )
})


test_that("config_load_package_options beholder eksisterende pakkeoptions uten overwrite", {
  withr::local_options(
    list(
      kh.paths = NULL,
      kh.package_opts = NULL,
      kh.dim.tab = NULL,
      khfunctions.year = 2025,
      khfunctions.root = NULL
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(
        list(
          kh.paths = list(
            database = list(
              khelsa = "test.accdb"
            )
          ),
          kh.package_opts = list(
            khfunctions = "config-khfunctions.yml"
          )
        )
      )
    }
    
    list(
      khfunctions.year = 2026,
      khfunctions.root = "O:/"
    )
  }
  
  mockery::stub(
    config_load_package_options,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_load_package_options,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  config_load_package_options(
    package = "khfunctions",
    overwrite = FALSE
  )
  
  testthat::expect_identical(
    getOption("khfunctions.year"),
    2025
  )
  
  testthat::expect_identical(
    getOption("khfunctions.root"),
    "O:/"
  )
})


test_that("config_load_package_options overskriver pakkeoptions med overwrite", {
  withr::local_options(
    list(
      kh.paths = NULL,
      kh.package_opts = NULL,
      kh.dim.tab = NULL,
      khfunctions.year = 2025,
      khfunctions.root = NULL
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(
        list(
          kh.paths = list(
            database = list(
              khelsa = "test.accdb"
            )
          ),
          kh.package_opts = list(
            khfunctions = "config-khfunctions.yml"
          )
        )
      )
    }
    
    list(
      khfunctions.year = 2026,
      khfunctions.root = "O:/"
    )
  }
  
  mockery::stub(
    config_load_package_options,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_load_package_options,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  config_load_package_options(
    package = "khfunctions",
    overwrite = TRUE
  )
  
  testthat::expect_identical(
    getOption("khfunctions.year"),
    2026
  )
  
  testthat::expect_identical(
    getOption("khfunctions.root"),
    "O:/"
  )
})


test_that("pakke uten egne configfiler får bare arkitekturoptions", {
  withr::local_options(
    list(
      kh.paths = NULL,
      kh.package_opts = NULL,
      kh.dim.tab = NULL
    )
  )
  
  mock_get_options <- mockery::mock(
    list(
      kh.paths = list(
        database = list(
          khelsa = "test.accdb"
        )
      ),
      kh.package_opts = list()
    )
  )
  
  mockery::stub(
    config_load_package_options,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_load_package_options,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  opts <- config_load_package_options(
    package = "ukjentpakke",
    overwrite = TRUE
  )
  
  testthat::expect_identical(
    opts$kh.dim.tab,
    c("AAR", "ALDER", "GEO")
  )
  
  testthat::expect_false(
    any(startsWith(names(opts), "ukjentpakke."))
  )
  
  mockery::expect_called(
    mock_get_options,
    1
  )
})


test_that("config_load_package_options krever enten config_files eller package", {
  testthat::expect_error(
    config_load_package_options(),
    "Angi enten 'config_files' eller 'package', men ikke begge.",
    fixed = TRUE
  )
  
  testthat::expect_error(
    config_load_package_options(
      config_files = c(kh = "config-arkitektur.yml"),
      package = "khfunctions"
    ),
    "Angi enten 'config_files' eller 'package', men ikke begge.",
    fixed = TRUE
  )
})


# config_package_options_are_default --------------------------------------

test_that("config_package_options_are_default returnerer TRUE når options matcher", {
  architecture_options <- list(
    kh.paths = list(
      database = list(
        khelsa = "test.accdb"
      )
    ),
    kh.package_opts = list(
      khfunctions = "config-khfunctions.yml"
    )
  )
  
  package_options <- list(
    khfunctions.year = 2026,
    khfunctions.root = "O:/"
  )
  
  withr::local_options(
    c(
      architecture_options,
      list(
        kh.dim.tab = c("AAR", "ALDER", "GEO")
      ),
      package_options
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(architecture_options)
    }
    
    package_options
  }
  
  mockery::stub(
    config_package_options_are_default,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_package_options_are_default,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  testthat::expect_true(
    config_package_options_are_default(
      package = "khfunctions"
    )
  )
})


test_that("config_package_options_are_default returnerer FALSE når options avviker", {
  architecture_options <- list(
    kh.paths = list(
      database = list(
        khelsa = "test.accdb"
      )
    ),
    kh.package_opts = list(
      khfunctions = "config-khfunctions.yml"
    )
  )
  
  package_options <- list(
    khfunctions.year = 2026,
    khfunctions.root = "O:/"
  )
  
  withr::local_options(
    c(
      architecture_options,
      list(
        kh.dim.tab = c("AAR", "ALDER", "GEO")
      ),
      list(
        khfunctions.year = 2025,
        khfunctions.root = "O:/"
      )
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(architecture_options)
    }
    
    package_options
  }
  
  mockery::stub(
    config_package_options_are_default,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_package_options_are_default,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  testthat::expect_false(
    config_package_options_are_default(
      package = "khfunctions"
    )
  )
})


test_that("config_package_options_are_default inkluderer dynamiske options", {
  architecture_options <- list(
    kh.paths = list(
      database = list(
        khelsa = "test.accdb"
      )
    ),
    kh.package_opts = list(
      khfunctions = "config-khfunctions.yml"
    )
  )
  
  package_options <- list(
    khfunctions.year = 2026
  )
  
  dynamic_options <- list(
    "khfunctions.snutter" = function() {
      c("snutt_a", "snutt_b")
    }
  )
  
  withr::local_options(
    c(
      architecture_options,
      list(
        kh.dim.tab = c("AAR", "ALDER", "GEO")
      ),
      package_options,
      list(
        khfunctions.snutter = c("snutt_a", "snutt_b")
      )
    )
  )
  
  mock_get_options <- function(config_files,
                               dynamic_options = list(),
                               repo = "helseprofil/backend",
                               branch = "main") {
    if (identical(
      unname(config_files),
      "config-arkitektur.yml"
    )) {
      return(architecture_options)
    }
    
    package_options
  }
  
  mockery::stub(
    config_package_options_are_default,
    "config_get_options",
    mock_get_options
  )
  
  mockery::stub(
    config_package_options_are_default,
    "get_all_tabdims",
    function(path) {
      c("AAR", "ALDER", "GEO")
    }
  )
  
  testthat::expect_true(
    config_package_options_are_default(
      package = "khfunctions",
      dynamic_options = dynamic_options
    )
  )
})


# package_update_available ------------------------------------------------

test_that("package_update_available finner nyere versjon", {
  mockery::stub(
    package_update_available,
    "utils::packageDescription",
    function(...) {
      list(Version = "1.2.0")
    }
  )
  
  mockery::stub(
    package_update_available,
    "readLines",
    function(...) {
      c(
        "Package: khfunctions",
        "Version: 1.3.0"
      )
    }
  )
  
  testthat::expect_true(
    package_update_available("khfunctions")
  )
})


test_that("package_update_available returnerer FALSE når versjoner er like", {
  mockery::stub(
    package_update_available,
    "utils::packageDescription",
    function(...) {
      list(Version = "1.3.0")
    }
  )
  
  mockery::stub(
    package_update_available,
    "readLines",
    function(...) {
      c(
        "Package: khfunctions",
        "Version: 1.3.0"
      )
    }
  )
  
  testthat::expect_false(
    package_update_available("khfunctions")
  )
})


test_that("package_update_available returnerer FALSE når GitHub er utilgjengelig", {
  mockery::stub(
    package_update_available,
    "utils::packageDescription",
    function(...) {
      list(Version = "1.2.0")
    }
  )
  
  mockery::stub(
    package_update_available,
    "readLines",
    function(...) {
      stop("offline")
    }
  )
  
  testthat::expect_false(
    package_update_available("khfunctions")
  )
})


test_that("package_update_available returnerer FALSE når GitHub-versjon mangler", {
  mockery::stub(
    package_update_available,
    "utils::packageDescription",
    function(...) {
      list(Version = "1.0.0")
    }
  )
  
  mockery::stub(
    package_update_available,
    "readLines",
    function(...) {
      c(
        "Package: khfunctions",
        "Title: test"
      )
    }
  )
  
  testthat::expect_false(
    package_update_available("khfunctions")
  )
})


test_that("package_update_available returnerer FALSE når pakken ikke er installert", {
  testthat::expect_false(
    package_update_available(
      "en_pakke_som_helt_sikkert_ikke_finnes"
    )
  )
})
