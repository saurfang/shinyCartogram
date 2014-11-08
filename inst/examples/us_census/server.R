shinyServer(function(input, output, session) {

  #Create cartogram object and pass base dataset and column definition
  map <- createCartogram(session, "cartogram")
  session$onFlushed(once = TRUE, function() {
    map$setData(rename(nst2013, name = NAME))
    map$defineColumns(select(columns, title = name, name = key, format))
  })

  #Update scale variable
  observe({
    map$scaleBy(filter(columns, name == input$scaleBy, years == input$year)$key)
  })

  #Update color variable
  observe({
    map$colorBy(filter(columns, name == input$colorBy, years == input$year)$key)
  })

  #Update choices based on year selected
  observe({
    choices <- filter(columns, is.na(years) | years == input$year)$name
    updateSelectInput(session, "scaleBy", choices = choices)
    updateSelectInput(session, "colorBy", choices = choices)
  })
})
