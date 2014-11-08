#' Create a Cartogram object in R
#'
#' This function is called from \file{server.R} and returns an object that can
#' be used to manipulate the cartogram from R.
#' @param session The \code{session} argument passed through from the
#'   \code{\link[shiny]{shinyServer}} server function.
#' @param outputId The string identifier that was passed to the corresponding
#'   \code{\link{cartogramOutput}()}.
#' @return A list of methods. See the package vignette \code{vignette('intro',
#'   'cartogram'} for details.
#' @importFrom shiny renderText
#' @export
createCartogram <- function(session, outputId) {
  # Need to provide some trivial output, just to get the binding to render
  session$output[[outputId]] <- renderText("")

  # This function is how we "dynamically" invoke code on the client. The
  # method parameter indicates what leaflet operation we want to perform,
  # and the other arguments will be serialized to JS objects and used as
  # client side function args.
  send <- function(method, func, msg) {

    msg <- msg[names(formals(func))]
    names(msg) <- NULL

    origDigits <- getOption('digits')
    options(digits=22)
    on.exit(options(digits=origDigits))
    session$sendCustomMessage('cartogram', list(
      mapId = outputId,
      method = method,
      args = msg
    ))
  }

  # Turns a call like:
  #
  #     stub(expression(setView(lat, lng, zoom, forceReset = FALSE)))
  #
  # into:
  #
  #     list(setView = function(lat, lng, zoom, forceReset = FALSE) {
  #       send("setView", sys.function(), as.list(environment()))
  #     })
  stub <- function(p) {
    # The function name is the first element
    name <- as.character(p[[1]])

    # Get textual representation of the expression; change name to "function"
    # and add a NULL function body
    txt <- paste(deparse(p), collapse = "\n")
    txt <- sub(name, "function", txt, fixed = TRUE)
    txt <- paste0(txt, "NULL")

    # Create the function
    func <- eval(parse(text = txt))

    # Replace the function body
    body(func) <- substituteDirect(
      quote(send(name, sys.function(), as.list(environment()))),
      list(name = name)
    )
    environment(func) <- environment(send)

    # Return as list
    structure(list(func), names = name)
  }

  obj <- lapply(expression(
    setView(lat, lng, zoom, forceReset = FALSE),
    setData(data),
    defineColumns(columns),
    scaleBy(column),
    colorBy(column)
  ), stub)
  structure(unlist(obj, recursive = FALSE), class = "cartogram_map")
}

#' Create a \code{svg} element for a Cartogram
#'
#' This function is called from \file{ui.R} (or from
#' \code{\link[shiny]{renderUI}()}); it creates a \code{<svg>} that will contain
#' a cartogram map.
#' @param outputId the id of the \samp{<svg>} element
#' @param width,height The width and height of the map. They can either take a
#'   CSS length (e.g. \code{400px} or \code{50\%}) or a numeric value which will
#'   be interpreted as pixels.
#' @param topojson The URL for the topojson which encodes the map topology such
#'   as boundaries and names. (the us states are used by default). See
#'   \url{https://github.com/mbostock/topojson/wiki} for information about
#'   where to find other maps or creating your own map.
#' @param colors The
#' @return An HTML tag list.
#' @importFrom shiny addResourcePath
#' @importFrom htmltools htmlDependency attachDependencies tagList singleton tags tag validateCssUnit
#' @importFrom jsonlite toJSON
#' @importFrom RColorBrewer brewer.pal
#' @export
cartogramOutput <- function(outputId, width = "100%", height = "500px",
                            topojson = "cartogram/data/us-states-segmentized.topojson",
                            colors = brewer.pal(3, "RdYlBu")) {
  addResourcePath("cartogram", system.file("www", package="shinyCartogram"))

  d3Dep <- htmlDependency("d3", "3.4.13", c(href = "//cdnjs.cloudflare.com/ajax/libs/d3/3.4.13/"),
                          script = "d3.min.js")
  topojsonDep <- htmlDependency("topojson", "1.1.0", c(href = "//cdnjs.cloudflare.com/ajax/libs/topojson/1.1.0"),
                                script = "topojson.min.js")

  attachDependencies(
    tagList(
      singleton(
        tags$head(
          tags$link(rel="stylesheet", type="text/css", href="cartogram/cartogram.css"),
          tags$script(src="cartogram/cartogram.js"),
          tags$script(src="cartogram/binding.js")
        )
      ),
      tags$div(id = outputId, class = "cartogram-map-output",
               style = paste("width:", validateCssUnit(width), ";", "height:", validateCssUnit(height)),
               tag("svg", c(class = "cartogram-map")),
               `data-topojson` = topojson,
               `data-colors` = toJSON(colors))
    ),
    list(d3Dep, topojsonDep)
  )
}

cartogramColumn <- function(name, title = name, format = NULL) {
  list(name = name, title = title, format = format)
}
