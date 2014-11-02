shinyUI(fixedPage(
  titlePanel("Cartograms with d3 & TopoJSON"),

  HTML('<a href="https://github.com/saurfang/shinyCartogram"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/365986a132ccd6a44c23a9169022c0b5c890c387/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f7265645f6161303030302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png"></a>'),

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
       colors by <a href="http://colorbrewer2.org">colorbrewer</a>.
       This replicates the work at <a href="http://prag.ma/code/d3-cartogram/">d3-cartogram</a>
       using Shiny.
       </p>
       </div>
       </div>
  ')
))
