BaseCountChart = function(){
  var area, areas, color, containerId, createLegend, data, display, duration, height, hideLegend, legend, legendWidth, legendOffset, line, paddingBottom, paddingLeft, showLegend, stack, stackedAreas, start, streamgraph, svg, transitionTo, width, x, xAxis, y, yAxis;
  var pLeft,pRight,pTop,pBot
  data = null;
  transitionTo = function(name) {
    if (name === "stream") {
      streamgraph();
    }
    if (name === "stack") {
      stackedAreas();
    }
    if (name === "area") {
      return areas();
    }
  };

  streamgraph = function(skip_transition) {
    var t;
    stack.offset("wiggle");
    stack(data);
    // accommodates the highest value + offset
    y.domain([
      0, d3.max(data[0].values.map(function(d) {
        return d.count0 + d.count;
      }))
    ]).range([height, 0]);

    // Line
    line.y(function(d) {
      return y(d.count+d.count0);
    });
    
    // area generator uses count0 from the layout
    area.y0(function(d) {
      return y(d.count0);
    }).y1(function(d) {
      return y(d.count0 + d.count);
    });
    // Y-axis transition
    svg.select(".y.axis").transition().duration(duration).call(yAxis).style("opacity",1e-6);
    // The transition
    if(skip_transition){
      t = svg.selectAll(".series")
    }else{
      t = svg.selectAll(".series").transition().duration(duration);
    };
    // D3 will take care of the details of transitioning
    t.select("path.area").style("fill-opacity", 1.0).attr("d", function(d) {
      return area(d.values);
    });
    // Hide Line
    return t.select("path.line").style("stroke-opacity", 1e-6).attr("d", function(d) {
      return line(d.values);
    });
  };

  stackedAreas = function() {
    var t;
    stack.offset("zero");
    stack(data);
    y.domain([
      0, d3.max(data[0].values.map(function(d) {
        return d.count0 + d.count;
      }))
    ]).range([height, 0]);
    line.y(function(d) {
      return y(d.count0);
    });
    area.y0(function(d) {
      return y(d.count0);
    }).y1(function(d) {
      return y(d.count0 + d.count);
    });
    // Y-axis transition
    svg.select(".y.axis").transition().duration(duration).call(yAxis).style("opacity",1.0);
    t = svg.selectAll(".series").transition().duration(duration);
    t.select("path.area").style("fill-opacity", 1.0).attr("d", function(d) {
      return area(d.values);
    });
    return t.select("path.line").style("stroke-opacity", 1e-6).attr("d", function(d) {
      return line(d.values);
    });
  };

  areas = function() {
    y.domain([
      0, d3.max(data[0].values.map(function(d) {
        return d.count;
      }))
    ]).range([height, 0]);
    
    line.y(function(d) {
      return y(d.count);
    });
    
    area.y1(function(d) {
      return y(d.count);
    }).y0(function(d){
      return (y(0));
    })
    // Y-axis transition
    svg.select(".y.axis").transition().duration(duration).call(yAxis).style("opacity",1.0);
    t = svg.selectAll(".series").transition().duration(duration);
    
    t.select("path.area").style("fill-opacity", 0.6).attr("d", function(d) {
      return area(d.values);
    });
    return t.select("path.line").style("stroke-opacity", 1.0).attr("d", function(d) {
      return line(d.values);
    });
  };
  createLegend = function() {
    var keys, legendG, legendHeight, BoxSpace, boxHeight, topPadding;
    boxDim = 20;
    topPadding = 10;
    BoxSpace = 40;
    container = document.getElementById('legend');
    legendWidth = container.scrollWidth;
    legendHeight = topPadding + data.length*BoxSpace
    legend = d3.select("#legend").append("svg").attr("width", legendWidth).attr("height", legendHeight);
    legendG = legend.append("g").attr("class", "panel");
    legendG.append("rect").attr("width", legendWidth).attr("height", legendHeight).attr("rx", 4).attr("ry", 4).attr("fill-opacity", 0.5).attr("fill", "white");
    keys = legendG.selectAll("g").data(data).enter().append("g").attr("transform", function(d, i) {
      return "translate(" + 5 + "," + (topPadding + BoxSpace * i) + ")";
    });
    
    keys.append("rect").attr("width", boxDim).attr("height", boxDim ).attr("rx", 4).attr("ry", 4).attr("fill", function(d) {
      return color(d.key);
    });
    
    return keys.append("text").text(function(d) {
      return d.key;
    }).attr("text-anchor", "left").attr("dx", "2.3em").attr("dy", "1.3em");
  };

  display = function(error, rawData) {
    data = rawData
    data.forEach(function(s) {
      s.values.forEach(function(d) {
        d.base = parseInt(d.base);
        return d.count = parseFloat(d.count);
      });
      return s.maxCount = d3.max(s.values, function(d) {
        return d.count;
      });
    });
    // why sort reverse?
    data.sort(function(a, b) {
      return b.maxCount - a.maxCount;
    });
    return start();
  };

  function init(graph_id){
    containerId = graph_id;
    // Setup Button Clicks
    d3.selectAll(".switch").on("click", function(d) {
      var id;
      d3.event.preventDefault();
      id = d3.select(this).attr("id");
      return transitionTo(id);
    });
    
    // Setup global values
    var selection = d3.select("#"+graph_id);
    var container = document.getElementById(graph_id);
    
    legendOffset = 30;
    width = container.scrollWidth;
    height = container.scrollHeight *0.95;
    paddingBottom = height*0.05;
    paddingLeft = width*0.05;
    pLeft = width*0.05;
    pRight = width*0.9;
    pTop = height*0.9;
    pBot = height*0.05;
    
    duration = 750;
    x = d3.scale.linear().range([pLeft,pRight]);
    y = d3.scale.linear().range([pBot,pTop]);
    color = d3.scale.category10();

    area = d3.svg.area().interpolate("basis").x(function(d) {
      return x(d.base);
    });

    line = d3.svg.line().interpolate("basis").x(function(d) {
      return x(d.base);
    });

    stack = d3.layout.stack().values(function(d) {
      return d.values;
    }).x(function(d) {
      return d.base;
    }).y(function(d) {
      return d.count;
    }).out(function(d, y0, y) {
      return d.count0 = y0;
    }).order("reverse");

    xAxis = d3.svg.axis().scale(x).orient('bottom').tickSize(-height).tickPadding(8); //d3.time.format('%a %d')
    yAxis = d3.svg.axis().scale(y).orient('left').tickSize(-pRight);
    svg = selection.append("svg").attr("width", width+paddingLeft).attr("height", height + paddingBottom);
  };
  
  start = function(skip_transition) {
    var bases, g, index, maxX, requests;
    maxX = d3.max(data, function(d) {
      return d.values[d.values.length - 1].base;
    });
    
    x.domain([0, maxX]);
    // x-Axis
    svg.append("g").attr("class", "x axis").attr('transform', 'translate(0, ' + height +')').call(xAxis);
    // y-Axis
    svg.append("g").attr("class", "y axis").attr('transform','translate('+paddingLeft+',0)').call(yAxis);
    
    // emanate from middle of display
    area.y0(height / 2).y1(height / 2);

    //bind our data to create new group for each request type
    g = svg.selectAll(".series").data(data).enter();
    
    requests = g.append("g").attr("class", "series");

    // add some paths that will
    // be used to display the lines and
    // areas that make up the charts
    requests.append("path").attr("class", "area").style("fill", function(d) {
      return color(d.key);
    }).attr("d", function(d) {
      return area(d.values);
    });
    
    requests.append("path").attr("class", "line").style("stroke-opacity", 1e-6);
    
    createLegend();
    return streamgraph(skip_transition);
  };
  
  function clear(){
    svg.remove()
    legend.remove()
  };
  
  function resize(){
    if(data){
      clear()
      init(containerId);
      start(true);
    }
  };
  
  function load(path){
    d3.json(path,display);
  }
  return {
    init : init,
    load : load,
    resize: resize
  }
}();
window.onresize = function(){BaseCountChart.resize()};