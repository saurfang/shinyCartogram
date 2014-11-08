shinyCartogram
==============
[![Build Status](https://travis-ci.org/saurfang/shinyCartogram.png?branch=master)](https://travis-ci.org/saurfang/shinyCartogram)

This R package wraps [d3-cartogram](https://github.com/shawnbot/d3-cartogram) in
a reusable [Shiny](http://rstudio.com/shiny) component. 
The concept and R Shiny binding implementation borrows heavily from 
[leaflet-shiny](https://github.com/jcheng5/leaflet-shiny).

[cartogram.js](https://github.com/shawnbot/d3-cartogram/blob/master/cartogram.js) is a JavaScript
implementation of [an algoritm to construct continuous area cartograms](http://lambert.nico.free.fr/tp/biblio/Dougeniketal1985.pdf),
by James A. Dougenik, Nicholas R. Chrisman and Duane R. Niemeyer, &copy;1985 
by the Association of American Geographers.

This [example](https://saurfang.shinyapps.io/shinyCartogram/) replicates the original demo that
[Shawn Allen](http://stamen.com/studio/shawn) made for his [d3-cartogram](https://github.com/shawnbot/d3-cartogram).
This R package has made it possible for you to only focus on providing the dataset and column definitions
rather than writing boilerplate codes that creates the map and associated visual updates.
