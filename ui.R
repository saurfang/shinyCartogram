shinyUI(fixedPage(
  titlePanel("Cartograms with d3 & TopoJSON"),

  flowLayout(
    selectInput("scaleBy", "Scale by", columnChoices),
    selectInput("colorBy", "Color by", columnChoices),
    selectInput("year", "in", c(2010, 2011))
  ),

  cartogramOutput("cartogram"),

  HTML('<div id="about">
       <h2>About</h2>
       <p><a href="cartogram.js">cartogram.js</a> is a JavaScript implementation of
       <a href="http://lambert.nico.free.fr/tp/biblio/Dougeniketal1985.pdf">an algoritm to construct continuous area cartograms</a>,
       by James A. Dougenik, Nicholas R. Chrisman and Duane R. Niemeyer,
       &copy;1985 by the Association of American Geographers. This example combines
       <a href="http://github.com/mbostock/topojson">TopoJSON</a>-encoded
       boundaries of the United States from
       <a href="http://www.naturalearthdata.com/downloads/110m-cultural-vectors/">Natural Earth</a>
       with
       <a href="http://www.census.gov/popest/data/state/totals/2011/">2011 US Census population estimates</a>
       to size each state proportionally.</p>

       <p>Built by
       <a href="https://github.com/saurfang/shinyCartogram">Forest Fang</a>
       according to the wonderful d3-cartogram by
       <a href="http://stamen.com/studio/shawn">Shawn Allen</a>
       at <a href="http://stamen.com">Stamen</a>. But
       <a href="http://d3js.org">d3.js</a> does most of the heavy lifting;
       colors by <a href="http://colorbrewer2.org">colorbrewer</a>.</p>
       </div>
       </div>
  ')
))
