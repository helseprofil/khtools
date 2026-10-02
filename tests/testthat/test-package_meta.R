# get_package_options ----
test_that("get_package_options merges global and package config", {
  
  mockery::stub(get_package_options, "yaml::yaml.load_file",
                function(path) {
                  if (grepl("config-globals.yml$", path)) {
                    return(list(year = 2026, root = "O:/", db = "test.accdb"))
                  }
                  if (grepl("config-khfunctions.yml$", path)) {
                    return(list(db = "kh.accdb", illegal = "abc"))
                  }
                  stop("unexpected file")
                })
  
  opts <- get_package_options("khfunctions")
  expect_identical(opts,
    list(khfunctions.year = 2026,
         khfunctions.root = "O:/",
         khfunctions.db = "kh.accdb",
         khfunctions.illegal = "abc"
    )
  )
})

test_that("package options override global options", {
  
  mockery::stub(get_package_options, "yaml::yaml.load_file",
                function(path) {
                  if (grepl("globals", path)) {
                    return(list(year = 2026, db = "global.accdb"))
                  }
                  list(db = "package.accdb")
                  })
  opts <- get_package_options("khfunctions")
  expect_identical(opts$khfunctions.db, "package.accdb")
  expect_identical(opts$khfunctions.year, 2026)
})

test_that("load_package_options sets options", {
  old_opts <- options()
  on.exit(options(old_opts), add = TRUE)
  mockery::stub(load_package_options, "get_package_options",
                function(...) {
                  list(khfunctions.year = 2026, khfunctions.root = "O:/")
                  })
  
  ret <- load_package_options("khfunctions")
  expect_identical(getOption("khfunctions.year"), 2026)
  expect_identical(getOption("khfunctions.root"),"O:/")
  ret <- load_package_options("khfunctions")
  
  expect_identical(ret, list(khfunctions.year = 2026, khfunctions.root = "O:/"))
})

test_that("missing package config falls back to globals", {
  
  mockery::stub(get_package_options, "yaml::yaml.load_file",
                function(path) {
                  if (grepl("config-globals.yml$", path)) {
                    return(list(year = 2026, root = "O:/"))
                  }
                  stop("file not found")
                  })
  
  opts <- get_package_options("khfunctions")
  
  expect_identical(opts, list(khfunctions.year = 2026, khfunctions.root = "O:/"))
})

#package_options_are_default ----
test_that("package_options_are_default returns TRUE when options match", {
  old_opts <- options()
  on.exit(options(old_opts), add = TRUE)
  options(khfunctions.year = 2026, khfunctions.root = "O:/")
  mockery::stub(package_options_are_default, "get_package_options",
                function(...) {
                  list(khfunctions.year = 2026, khfunctions.root = "O:/")
                })
  expect_true(package_options_are_default("khfunctions"))
})

test_that("package_options_are_default returns FALSE when options differ", {
  old_opts <- options()
  on.exit(options(old_opts), add = TRUE)
  options(khfunctions.year = 2025, khfunctions.root = "O:/")
  mockery::stub(package_options_are_default, "get_package_options",
                function(...) {
                  list(khfunctions.year = 2026, khfunctions.root = "O:/")
                })
  expect_false(package_options_are_default("khfunctions"))
})

# package_update_available ----
test_that("package_update_available detects newer version", {
  mockery::stub(package_update_available, "utils::packageDescription", function(...) list(Version = "1.2.0"))
  mockery::stub(package_update_available, "readLines", 
                function(...) {
                  c("Package: khfunctions", "Version: 1.3.0")
                })
  expect_true(package_update_available("khfunctions"))
})

test_that("package_update_available returns FALSE when versions are equal", {
  
  mockery::stub(package_update_available, "utils::packageDescription",
                function(...) list(Version = "1.3.0"))
  
  mockery::stub(package_update_available, "readLines",
                function(...) {
                  c("Package: khfunctions", "Version: 1.3.0")
                })
  
  expect_false(package_update_available("khfunctions"))
})

test_that("package_update_available returns FALSE when github unavailable", {
  
  mockery::stub(package_update_available, "readLines", function(...) stop("offline"))
  expect_false(package_update_available("khfunctions"))
})

test_that("package_update_available returns FALSE when version is missing", {
  mockery::stub(package_update_available, "utils::packageDescription",
                function(...) list(Version = "1.0.0"))
  
  mockery::stub(package_update_available, "readLines",
                function(...) c("Package: khfunctions", "Title: test"))
  expect_false(package_update_available("khfunctions"))
})
