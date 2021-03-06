if (FALSE) {

drake_context("always skipped")

test_with_dir("can keep going in parallel", {
  skip_on_cran() # CRAN gets whitelist tests only (check time limits).
  plan <- drake_plan(
    a = stop(123),
    b = a + 1
  )
  make(
    plan, jobs = 2, session_info = FALSE, keep_going = TRUE, verbose = FALSE)
  expect_error(readd(a))
  expect_equal(readd(b), numeric(0))
})

test_with_dir("drake_debug()", {
  skip_on_cran()
  load_mtcars_example()
  my_plan$command[2] <- "simulate(48); stop(1234)"
  config <- drake_config(my_plan, lock_envir = TRUE)
  expect_error(make(my_plan), regexp = "1234")
  out <- drake_debug(large, config = config)
  out <- drake_debug(
    "large", config = config, verbose = "false", character_only = TRUE)
  expect_true(is.data.frame(out))
  my_plan$command <- lapply(
    X = as.list(my_plan$command),
    FUN = function(x) {
      parse(text = x)[[1]]
    }
  )
  for (i in 1:2) {
    clean(destroy = TRUE)
    load_mtcars_example()
    make(my_plan)
    config <- drake_config(my_plan)
    expect_true(config$cache$exists("small"))
    clean(small)
    expect_false(config$cache$exists("small"))
    out <- drake_debug(small, config = config)
    expect_false(config$cache$exists("small"))
    expect_true(is.data.frame(out))
  }
})

test_with_dir("clustermq error messages get back to master", {
  plan <- drake_plan(a = stop(123))
  options(clustermq.scheduler = "multicore")
  for (caching in c("worker", "master")) {
    expect_error(
      make(
        plan,
        parallelism = "clustermq",
        caching = "worker"
      ),
      regexp = "123"
    )
  }
})

test_with_dir("forks + lock_envir = informative error msg", {
  # Don't run this test for real because (1) we would have to add
  # furrr to "Suggests" and (2) at some point, base R may be patched
  # so forking in the parallel package does not give this warning anyway.
  regexp <- "workaround"
  plan <- drake_plan(x = parallel::mclapply(1:2, identity, mc.cores = 2))
  expect_warning(
    make(plan, envir = globalenv(), lock_envir = TRUE),
    regexp = regexp
  )
  future::plan(future::multicore)
  plan <- drake_plan(
    # install.packages("furrr") # nolint
    # Not in "Suggests"
    x = eval(parse(text = "furrr::future_map(1:2, identity)"))
  )
  expect_error(
    make(plan, envir = globalenv(), lock_envir = TRUE),
    regexp = regexp
  )
})

}
