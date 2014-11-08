#' US Population Estimates (State Totals: Vintage 2013)
#'
#' Population, population change and estimated components of population change:
#' April 1, 2010 to July 1, 2013 (NST-EST2013-alldata)
#' @docType data
#' @format A data frame containing \code{NAME} for state name, and
#' population estimates and related metrics from 2010 to 2013.
#' @source The US Census Bureau:
#'   \url{http://www.census.gov/popest/data/state/totals/2013}
#' @export
#' @examples
#' library(shinyCartogram)
#' str(nst2013)
nst2013 <- NULL
if (file.exists('inst/csv/NST_EST2013_ALLDATA.csv')) {
  nst2013 <- read.csv(text = readLines('inst/csv/NST_EST2013_ALLDATA.csv', encoding = 'UTF-8'))
}
