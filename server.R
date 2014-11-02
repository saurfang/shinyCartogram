shinyServer(function(input, output, session) {

  map <- createCartogram(session, "cartogram")
  session$onFlushed(once = TRUE, function() {
    map$setData(rename(nst_2011, name = NAME))
    map$defineColumns(select(columns, title = name, name = key, format))
  })

  observe({
    map$scaleBy(filter(columns, name == input$scaleBy, years == input$year)$key)
  })

  observe({
    map$colorBy(filter(columns, name == input$colorBy, years == input$year)$key)
  })

  observe({
    choices <- filter(columns, is.na(years) | years == input$year)$name
    updateSelectInput(session, "scaleBy", choices = choices)
    updateSelectInput(session, "colorBy", choices = choices)
  })
})
