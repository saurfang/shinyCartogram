library(shinyCartogram)
library(jsonlite)
library(dplyr)

#Javascript code to format number as percent
percent <- "(function() {
  var fmt = d3.format('.2f');
  return function(n) { return fmt(n) + '%'; };
})()";

#Definition borrowed from: https://github.com/shawnbot/d3-cartogram/blob/master/index.html
fields <- list(
  list(name = "(no scale)", id = "none"),
  list(name = "Census Population", id = "censuspop", key = "CENSUS%dPOP", years = c(2010)),
  list(name = "Estimate Base", id = "censuspop", key = "ESTIMATESBASE%d", years = c(2010)),
  list(name = "Population Estimate", id = "popest", key = "POPESTIMATE%d"),
  list(name = "Population Change", id = "popchange", key = "NPOPCHG_%d", format = "'+,'"),
  list(name = "Births", id = "births", key = "BIRTHS%d"),
  list(name = "Deaths", id = "deaths", key = "DEATHS%d"),
  list(name = "Natural Increase", id = "natinc", key = "NATURALINC%d", format = "'+,'"),
  list(name = "Int'l Migration", id = "intlmig", key = "INTERNATIONALMIG%d", format = "'+,'"),
  list(name = "Domestic Migration", id = "domesticmig", key = "DOMESTICMIG%d", format = "'+,'"),
  list(name = "Net Migration", id = "netmig", key = "NETMIG%d", format = "'+,'"),
  list(name = "Residual", id = "residual", key = "RESIDUAL%d", format = "'+,'"),
  list(name = "Birth Rate", id = "birthrate", key = "RBIRTH%d", years = 2011:2013, format = percent),
  list(name = "Death Rate", id = "deathrate", key = "RDEATH%d", years = 2011:2013, format = percent),
  list(name = "Natural Increase Rate", id = "natincrate", key = "RNATURALINC%d", years = 2011:2013, format = percent),
  list(name = "Int'l Migration Rate", id = "intlmigrate", key = "RINTERNATIONALMIG%d", years = 2011:2013, format = percent),
  list(name = "Net Domestic Migration Rate", id = "domesticmigrate", key = "RDOMESTICMIG%d", years = 2011:2013, format = percent),
  list(name = "Net Migration Rate", id = "netmigrate", key = "RNETMIG%d", years = 2011:2013, format = percent)
)

#Rearrange column definitions into data.frame
columns <- lapply(fields, function(field){
    key <- field$key
    if(!is.null(key) && grepl("%d", key) && is.null(field$years)) {
      field$years <- 2010:2013
    }
    data.frame(field, stringsAsFactors = FALSE)
  }) %>%
  rbind_all %>%
  mutate(key = mapply(function(key, year) {
    if(!is.na(year)) {
      gsub("%d", year, key)
    } else {
      key
    }
  }, key, years, USE.NAMES = FALSE))

#Choice list for scale/color variable
columnChoices <- unique(columns$name)
