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
          zoom = d3.behavior.zoom()
          .translate([-38, 32])
          .scale(0.94)
          .scaleExtent([0.5, 10.0])
          .on("zoom", updateZoom),
          layer = svg.append("g"),
          states = layer.append("g")
          .selectAll("path");

        updateZoom();

        function updateZoom() {
          var scale = zoom.scale();
          layer.attr("transform",
            "translate(" + zoom.translate() + ") " +
            "scale(" + [scale, scale] + ")");
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

        $el.data('cartogram-map', {});

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
              //return d.properties.NAME;
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
      if (!key) return;

      var columns = $el.data('cartogram-columns');
      var column = {
        name: key
      };
      if (columns.hasOwnProperty(key)) {
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

      if(states === undefined) return;

      var scaleColumn = this.getColumn($el, $el.data('cartogram-scaleBy')),
        scaleValue = this.getValue(scaleColumn),
        colorColumn = this.getColumn($el, $el.data('cartogram-colorBy')) || scaleColumn,
        colorValue = this.getValue(colorColumn);

      var scaleValues = states.data()
        .map(scaleValue)
        .filter(function(n) {
          return isFinite(n);
        })
        .sort(d3.ascending),
        colorValues = states.data()
        .map(colorValue)
        .filter(function(n) {
          return isFinite(n);
        })
        .sort(d3.ascending),
        lo = colorValues[0],
        hi = colorValues[colorValues.length - 1];

      if(scaleValues.length * colorValues.length === 0) {
        return this.reset($el);
      }

      var color = d3.scale.linear()
        .range($el.data('colors'))
        .domain(lo < 0 ? [lo, 0, hi] : [lo, d3.mean(colorValues), hi]);

      // normalize the scale to positive numbers
      var scale = d3.scale.linear()
        .domain([scaleValues[0], scaleValues[scaleValues.length - 1]])
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
           var arr = [
              d.properties.name,
              scaleColumn.title + ": " + scaleColumn.format(scaleValue(d))
            ];
          if(scaleColumn !== colorColumn) {
            arr.push(colorColumn.title + ": " + scaleColumn.format(colorValue(d)));
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

  methods.setView = function(lat, lng, zoom, forceReset) {
    this.data('cartogram-map').zoom.translate([lat, lng]).scale(zoom);
    if (forceRest) {
      cartogramBinding.reset(this);
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

  methods.defineColumns = function(data) {
    updateAttribute(this, nestRollup(data), 'columns');
  };

  methods.scaleBy = function(column) {
    updateAttribute(this, column, 'scaleBy');
  };

  methods.colorBy = function(column) {
    updateAttribute(this, column, 'colorBy');
  };
})();
