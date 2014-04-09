d3.linechart = function(config){
  var chart = {};
  var area, areas,brushable, color, containerId, data, div, height, line, showLegend,start, svg, tooltipName, width, x, xAxis, y, yAxis, minY, maxY;
  data = null;
  containerId = config.graph;
  tooltipName = config.tooltip;
  domainType = config.domaintype||'ordinal';
  mouseoverFunc = config.mouseover;
  mouseclickFunc = config.mouseclick;
  // Setup global values
  var selection = d3.select(containerId);
  var m = config.margins || [0, 60, 100, 80]; // margins
  width = selection.property('scrollWidth') - m[1] - m[3];
  height = selection.property('scrollHeight') - m[0] - m[2];
  var lineColor = "#069";
  var negColor = "#909"
  var highlightColor = "#f70";

  function mouseclick(data,idx) {
    var item = d3.select(this);
    if(mouseclickFunc){mouseclickFunc.call(item.datum());}
  }
  function mouseover(data,idx) {
    var item = d3.select(this);
    if(mouseoverFunc){mouseoverFunc.call(this,item,idx,div,x,y);return;}
    chart.highlight( item.data()[0].id );
    div.text(item.data()[0][tooltipName])
    .style("left", (d3.event.pageX - 80) + "px")
    .style("top", (d3.event.pageY - 35) + "px")
    .style("opacity",1)
  }
  function mouseout() {
    var item = d3.select(this);
    chart.unhighlight(item.data()[0].id);
    div.text(item.data()[0][tooltipName])
    .style("opacity",0)
  }
  function brush(){
    y.domain(brushable.empty() ? [minY,maxY] : brushable.extent());
    svg.select(".y.axis").attr("display",'').call(yAxis);
    svg.selectAll(".series").select("path.line").attr("d", function(d) { return line(d.values)})
  }
  function brushEnd() {

  }
  function drawLines(){
    // Add the line to each data element of the series group
    t = svg.selectAll(".series").select("path.line")
      .style("stroke",function(d){return d.r<0 ? negColor: lineColor})
      //.style("stroke-width",function(d){return d.id==highlight_id ? 3: 1})
      //.style("stroke",lineColor)
      .style("opacity",0.4)
      .style("stroke-width",2)
      .attr("id",function(d){return "i"+d.id})
      .attr("d", function(d) { return line(d.values)})
      .on("mouseover", mouseover)
      //.on("mousemove", mousemove)
      .on("mouseout", mouseout)
      .on("click",mouseclick);
  }
  //Request and display data
  chart.load = function(path){
    d3.json(path,display);
  }
  chart.render = function(data){
    display(null,data);
  }
  // Add the tooltip
  div = selection.append("div")
    .attr("class", "tooltip")
    .style("opacity", 1e-6);
  // Highlight series with given id
  chart.highlight=function(itemId){
    var item = d3.select('#i'+itemId).style("stroke", highlightColor).style('opacity', 1).style('stroke-width',3);
    item.node().parentNode.parentNode.appendChild(item.node().parentNode);
  };
  // Un-highlight series with given id
  chart.unhighlight=function(itemId){
    //var item = d3.select('#i'+itemId).style("stroke", function(d){return d.r<0 ? negColor: lineColor}).style('opacity', 0.5).style('stroke-width',2);
    d3.selectAll("path.line").style("stroke", function(d){return d.r<0 ? negColor: lineColor}).style('opacity', 0.4).style('stroke-width',2);
  };
  //display the data
  var display = function(error, rawData) {
    var g, index, maxX, requests;
    data = rawData
    var highlight_id = rawData.highlight
    // Get the maximum of the nested values
    maxY = d3.max(data.map(function(item) {
        return d3.max(item.values.map(function(d) {
          return d.y;
        }))
      }))
    minY = d3.min(data.map(function(item) {
        return d3.min(item.values.map(function(d) {
          return d.y;
        }))
      }))
    if(minY > 0){minY=0}
    // Get all of the categories from the first entry
    categories = data[0].values.map(function(v){return v.x})
    // Setup Scale and domain
    if(domainType = 'linear'){
      maxX = d3.max(categories)
      x = d3.scale.linear()
        .domain([0,maxX])
        .range([0, width]);
    }else{
      x = d3.scale.ordinal()
        .domain(categories)
        .rangePoints([0, width]);
    }
    y = d3.scale.linear()
      .domain([minY, maxY])
      .range([height,0]);
    brushY = d3.scale.linear()
      .domain([minY, maxY])
      .range([height,0]);
    // Generate the curves
    line = d3.svg.line()
      .x(function(d,i) { return x(d.x); })
      .y(function(d,i) { return y(d.y); });
      
    var plotWidth = width+ m[1] + m[3];
    var plotHeight = height + m[0] + m[2]
    // Add SVG element
    svg = selection.append("svg")
      .attr("width", plotWidth)
      .attr("height", plotHeight)
    .append("g")
      .attr("transform", "translate(" + m[3] + ","+m[0]+")")
    //zoomable rect
    var plot = svg.append("rect")
        .attr("width", plotWidth)
        .attr("height", height)
        .style("fill", "#FAFAFA")
    //brush
    brushable = d3.svg.brush()
      .y(brushY)
      .on("brush", brush)
      .on("brushend",brushEnd)
    // y-Axis
    yAxis = d3.svg.axis().scale(y).ticks(4).orient("left");
    svg.append("g").attr("class", "y axis")
      .attr("transform", "translate("+(width+m[1]-1)+",0)")
      .call(yAxis)
    brushAxis = d3.svg.axis().scale(brushY).ticks(4).orient("left");
    svg.append("g").attr("class", "y brush")
      .attr("transform", "translate(-10,0)")
      .call(brushAxis)
      .call(brushable)
      .selectAll("rect")
        .attr("x", -10)
        .attr("width", 20);
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
    g = svg.append("svg")
      .attr("top",0)
      .attr("left",0)
      .attr("width",plotWidth)
      .attr("height",height)
      .attr("viewBox", "0 0 "+plotWidth+" "+height)
      .selectAll(".series").data(data).enter();
    requests = g.append("g").attr("class", "series")
    // add some paths that will be used to display the lines
    requests.append("path").attr("class", "line");
    drawLines();
  };
  
  return chart;
};