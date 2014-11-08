(function() {
  var maps = {};

  var cartogramBinding = new Shiny.OutputBinding();
  $.extend(cartogramBinding, {
    find: function(scope) {
      return $(scope).find(".cartogram-map-output");
    },
    renderValue: function(el, data) {
      var $el = $(el);

      var map = $el.data('cartogram-map');
      if (!map) {
        // A new map was detected. Create it, initialize supporting data
        // structures, and hook up event handlers.
        var id = this.getId(el);
        maps[id] = $el;

        var svg = d3.select('#' + id + ' svg'),
          view = $el.data('cartogram-view'),
          zoom = d3.behavior.zoom()
            .translate([view[0], view[1]])
            .scale(view[2])
            .scaleExtent([0.5, 10.0])
            .on("zoom", updateZoom),
          zoomPane = svg.append("g");

        //Add rect so zoom can be activated in empty space
        //zoomPane.append('rect')
        //    .attr('class', 'overlay')
        //    .attr('width', '100%')
        //    .attr('height', '100%');

        //Add layer for zoom to apply so empty rect doesn't move with it
        var layer = zoomPane.append("g"),
          states = layer.selectAll("path");

        zoomPane.call(zoom);
        updateZoom();

        function updateZoom() {
          layer.attr("transform",
            "translate(" + zoom.translate() + ") " +
            "scale(" + zoom.scale() + ")");
        }

        var proj = d3.geo.albersUsa(),
          topology,
          geometries,
          carto = d3.cartogram()
          .projection(proj)
          .properties(function(d) {
            var data = $el.data('cartogram-data') || {};
            return data[d.id];
          })
          .value(function(d) {
            return +d.properties.scale;
          });

        $el.data('cartogram-map', {
          states: states,
          zoom: zoom,
          carto: carto
        });

        d3.json($el.data('topojson'), function(topo) {
          topology = topo;
          geometries = topology.objects.states.geometries;

          var features = carto.features(topology, geometries),
            path = d3.geo.path()
            .projection(proj);

          states = states.data(features)
            .enter()
            .append("path")
            .attr("class", "state")
            .attr("id", function(d) {
              return d.id;
            })
            .attr("fill", "#fafafa")
            .attr("d", path);

          states.append("title");

          $el.data('cartogram-map', {
            topology: topology,
            geometries: geometries,
            states: states,
            zoom: zoom,
            carto: carto,
            proj: proj
          });

          this.reset($el);
        });
      }
    },
    reset: function($el) {
      var map = $el.data('cartogram-map');
      var carto = map.carto,
        topology = map.topology,
        geometries = map.geometries,
        proj = map.proj,
        states = map.states;

      if(topology === undefined || geometries === undefined) return;

      var features = carto.features(topology, geometries),
        path = d3.geo.path()
        .projection(proj);

      states.data(features)
        .transition()
        .duration(750)
        .ease("linear")
        .attr("fill", "#fafafa")
        .attr("d", path);

      states.select("title")
        .text(function(d) {
          return d.properties.name;
        });
    },
    getFormat: function(format) {
      if (typeof format === 'function') {
        return format;
      }

      var f = eval('f = ' + format);
      if (typeof f !== 'function') {
        return d3.format(f || ",");
      } else {
        return f;
      }
    },
    getColumn: function($el, key) {
      if (!key || typeof key !== 'string') return;

      var columns = $el.data('cartogram-columns');
      var column = {
        name: key
      };
      if (columns !== undefined && columns.hasOwnProperty(key)) {
        column = columns[key];
      }
      column.format = this.getFormat(column.format);
      return column;
    },
    getValue: function(column) {
      return function(d) {
        return +d.properties[column.name];
      };
    },
    update: function($el) {
      var map = $el.data('cartogram-map');
      var carto = map.carto,
        topology = map.topology,
        geometries = map.geometries,
        proj = map.proj,
        states = map.states;

      if(topology === undefined || geometries === undefined) return;

      var scaleColumn = this.getColumn($el, $el.data('cartogram-scaleBy')),
        scaleValue = this.getValue(scaleColumn),
        colorColumn = this.getColumn($el, $el.data('cartogram-colorBy')) || scaleColumn,
        colorValue = this.getValue(colorColumn);

      if(scaleColumn === undefined) {
        if(colorColumn === undefined) {
          return this.reset($el);
        }

        scaleValue = function(d) { return 1; };
        carto.iterations(0);
      } else {
        carto.iterations(8);
      }

      var scaleValues = states.data()
        .map(scaleValue)
        .filter(function(n) {
          return isFinite(n);
        }),
        colorValues = states.data()
        .map(colorValue)
        .filter(function(n) {
          return isFinite(n);
        }),
        lo = d3.min(colorValues),
        hi = d3.max(colorValues);

      if(scaleValues.length * colorValues.length === 0) {
        return this.reset($el);
      }

      //Support one/two/three colors scale
      var colorRange = $el.data('colors');
      if(typeof colorRange === 'string') {
        colorRange = ['white', colorRange];
      } else if(colorRange.length > 3) {
        colorRange = colorRange.slice(0, 3);
      }
      //Determine domain based on number of colors
      var colorDomain = [lo, hi];
      if(colorRange.length === 3) {
        colorDomain = lo * hi < 0 ? [lo, 0, hi] : [lo, d3.mean(colorValues), hi];
      }

      var color = d3.scale.linear()
        .range(colorRange)
        .domain(colorDomain);

      // normalize the scale to positive numbers
      var scale = d3.scale.linear()
        .domain([d3.min(scaleValues), d3.max(scaleValues)])
        .range([1, 1000]);

      // tell the cartogram to use the scaled values
      carto.value(function(d) {
        return scale(scaleValue(d));
      });

      // generate the new features, pre-projected
      var features = carto(topology, geometries).features;

      // update the data
      states.data(features)
        .select("title")
        .text(function(d) {
           var arr = [ d.properties.name ];
           if(scaleColumn !== undefined) {
             arr.push(scaleColumn.title + ": " + scaleColumn.format(scaleValue(d)));
           }
           if(scaleColumn !== colorColumn) {
             arr.push(colorColumn.title + ": " + colorColumn.format(colorValue(d)));
           }
           return arr.join("\n");
        });

      states.transition()
        .duration(750)
        .ease("linear")
        .attr("fill", function(d) {
          return color(colorValue(d));
        })
        .attr("d", carto.path);
    }
  });
  Shiny.outputBindings.register(cartogramBinding, "cartogram-output-binding");

  Shiny.addCustomMessageHandler('cartogram', function(data) {
    var mapId = data.mapId;
    var map = maps[mapId];
    if (!map)
      return;

    if (methods[data.method]) {
      methods[data.method].apply(map, data.args);
    } else {
      throw new Error('Unknown method ' + data.method);
    }
  });

  var methods = {};

  methods.setView = function(x, y, scale, forceReset) {
    this.data('cartogram-view', [x, y, scale]);
    var zoom = this.data('cartogram-map').zoom;
    if(zoom !== undefined) {
      zoom.translate([x, y]).scale(scale).event(this);

      if (forceReset) {
        cartogramBinding.reset(this);
      }
    }
  };

  var nestRollup = function(data) {
      var result = {};

      data.name.forEach(function(name, i) {
        var elem = {};
        Object.keys(data).forEach(function(key) {
          elem[key] = data[key][i];
        });
        result[name] = elem;
      });

      return result;
    },
    updateAttribute = function($el, data, attribute) {
      $el.data('cartogram-' + attribute, data);
      if(attribute === 'data') cartogramBinding.reset($el);
      cartogramBinding.update($el);
    };

  methods.setData = function(data) {
    updateAttribute(this, nestRollup(data), 'data');
  };

  methods.setColumns = function(data) {
    updateAttribute(this, nestRollup(data), 'columns');
  };

  methods.scaleBy = function(column) {
    updateAttribute(this, column, 'scaleBy');
  };

  methods.colorBy = function(column) {
    updateAttribute(this, column, 'colorBy');
  };
})();
