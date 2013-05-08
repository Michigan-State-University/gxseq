d3.linechart = function(config){
  //TODO: Work in progress, refactor hard coded for reuse with grid etc...
  var chart = {};
  var area, areas, color, containerId, data, height, line, showLegend,start, svg, tooltipName, width, x, xAxis, y, yAxis;
  data = null;
  containerId = config.graph;
  tooltipName = config.tooltip;
  mouseoverFunc = config.mouseover;
  // Setup global values
  var selection = d3.select(containerId);
  var m = config.margins || [0, 60, 100, 80]; // margins
  width = selection.property('scrollWidth') - m[1] - m[3];
  height = selection.property('scrollHeight') - m[0] - m[2];
  var lineColor = "#069";
  var highlightColor = "#d92";
  function mouseover(data,idx) {
    var item = d3.select(this);
    if(mouseoverFunc){mouseoverFunc.call(idx);}
    chart.highlight( item.data()[0].id );
    div.text(item.data()[0][tooltipName])
    .style("left", (d3.event.pageX - 80) + "px")
    .style("top", (d3.event.pageY - 35) + "px")
    .style("opacity",1)
  }
  function mouseout() {
    var item = d3.select(this);
    chart.unhighlight();
    div.text(item.data()[0][tooltipName])
    .style("opacity",0)
  }
  //Request and display data
  chart.load = function(path){
    d3.json(path,display);
  }
  chart.render = function(data){
    display(null,data);
  }
  // Add the tooltip
  var div = selection.append("div")
    .attr("class", "tooltip")
    .style("opacity", 1e-6);
  // Highlight series with given id
  chart.highlight=function(itemId){
    var item = d3.select('#i'+itemId).style("stroke", highlightColor).style('opacity', 1);
    item.node().parentNode.parentNode.appendChild(item.node().parentNode);
  };
  // Un-highlight series with given id
  chart.unhighlight=function(){
    d3.selectAll("path.line").style("stroke", lineColor).style('opacity', 0.5);
  };
  //display the data
  var display = function(error, rawData) {
    var g, index, maxX, requests;
    data = rawData
    var highlight_id = rawData.highlight
    // Get the maximum of the nested values
    var maxY = d3.max(data.map(function(item) {
        return d3.max(item.values.map(function(d) {
          return d.y;
        }))
      }))
    // Get all of the categories from the first entry
    categories = data[0].values.map(function(v){return v.x})
    // Setup Scale and domain
    x = d3.scale.ordinal()
      .domain(categories)
      .rangePoints([0, width]);
    y = d3.scale.linear()
      .domain([0, maxY])
      .range([height,0]);
    // Generate the curves
    line = d3.svg.line()
      .x(function(d,i) { return x(d.x); })
      .y(function(d,i) { return y(d.y); });
    // Add SVG element
    svg = selection.append("svg")
      .attr("width", width+ m[1] + m[3])
      .attr("height", height + m[0] + m[2])
    .append("g")
      .attr("transform", "translate(" + m[3] + ","+m[0]+")");
    // y-Axis
    yAxis = d3.svg.axis().scale(y).ticks(4).orient("left");
    svg.append("g").attr("class", "y axis").attr("transform", "translate(-25,0)").call(yAxis);
    // x-Axis - rotated text from : http://www.d3noob.org/2013/01/how-to-rotate-text-labels-for-x-axis-of.html
    xAxis = d3.svg.axis().scale(x)
    svg.append("g").attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
    .selectAll("text")  
      .style("text-anchor", "end")
      .attr("dx", "-.8em")
      .attr("dy", ".15em")
      .attr("transform", function(d) { return "rotate(-65)" });
    //bind our data to create new group for each type
    g = svg.selectAll(".series").data(data).enter();
    requests = g.append("g").attr("class", "series");
    // add some paths that will be used to display the lines
    requests.append("path").attr("class", "line");
    // Add the line to each data element of the series group
    t = svg.selectAll(".series").select("path.line")
      // .style("stroke",function(d){return d.id==highlight_id ? "#0B0": "#069"})
      // .style("stroke-width",function(d){return d.id==highlight_id ? 3: 1})
      .style("stroke",lineColor)
      .style("opacity",0.5)
      .attr("id",function(d){return "i"+d.id})
      .attr("d", function(d) { return line(d.values)})
      .on("mouseover", mouseover)
      //.on("mousemove", mousemove)
      .on("mouseout", mouseout);
  };
  
  return chart;
};