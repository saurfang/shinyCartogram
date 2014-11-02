library(jsonlite)
library(htmltools)
library(RColorBrewer)

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

  baseimpl <- function() {
    send(`__name__`, sys.function(), as.list(environment()))
  }

  # Turns a call like:
  #
  #     stub(setView(lat, lng, zoom, forceReset = FALSE))
  #
  # into:
  #
  #     list(setView = function(lat, lng, zoom, forceReset = FALSE) {
  #       send("setView", sys.function(), as.list(environment()))
  #     })
  stub <- function(prototype) {
    # Get the un-evaluated expression
    p <- substitute(prototype)
    # The function name is the first element
    name <- as.character(p[[1]])

    # Get textual representation of the expression; change name to "function"
    # and add a NULL function body
    txt <- paste(deparse(p), collapse = "\n")
    txt <- sub(name, "function", txt, fixed = TRUE)
    txt <- paste0(txt, "NULL")

    # Create the function
    func <- eval(parse(text = txt))

    # Replace the function body, using baseimpl's body as a template
    body(func) <- substituteDirect(
      body(baseimpl),
      as.environment(list("__name__"=name))
    )
    environment(func) <- environment(baseimpl)

    # Return as list
    structure(list(func), names = name)
  }

  structure(c(
    stub(setView(lat, lng, zoom, forceReset = FALSE)),
    stub(setData(data)),
    stub(defineColumns(columns)),
    stub(scaleBy(column)),
    stub(colorBy(column))
  ), class = "cartogram_map")
}

cartogramOutput <- function(outputId, width = "100%", height = "500px",
                            topojson = "cartogram/data/us-states.topojson",
                            colors = brewer.pal(3, "RdYlBu")) {
  #addResourcePath("cartogram", system.file("www", package="shinyCartogram"))

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

cartogramObject <- function(data = NULL, columns = NULL, scaleField = NULL, colorField = NULL) {

}

cartogramColumn <- function(name, title = name, format = NULL) {
  list(name = name, title = title, format = format)
}
