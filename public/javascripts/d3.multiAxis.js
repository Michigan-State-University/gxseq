d3.multiAxis = function(config){
  var chart = {};
  var area, areas,brushable, color, containerId, data, height, lines, showLegend,stack, start, svg, tooltipName,transVal, width, x, xAxis, XmultiAxis, XmultiDomains, y, yAxis, maxY;
  data = null;
  containerId = config.graph;
  tooltipName = config.tooltip;
  mouseoverFunc = config.mouseover;
  mouseclickFunc = config.mouseclick;
  var legendId = config.legendId;
  var switchClass = config.switchClass;
  var fontSize = 14;
  var duration = 500;
  // Setup global values
  var selection = d3.select(containerId);
  var lineColor = "#069";
  var negColor = "#909"
  var highlightColor = "#f70";
  // Add the tooltip
  var div = selection.append("div")
    .attr("class", "tooltip")
    .style("opacity", 1e-6);
    
  function mouseclick(data,idx) {
    // var item = d3.select(this);
    // if(mouseclickFunc){mouseclickFunc.call(item.datum());}
  }
  function mouseover(data,idx) {
    var item = d3.select(this);
    if(mouseoverFunc){mouseoverFunc.call(idx);}

    if(item.datum().series){
    }else{
      var parent = d3.select(item.node().parentNode);
      var parents = parent.node().parentNode.childNodes
      var parentIdx = 0;
      for (var i = 0; i < parents.length; ++i) {
        if(parents[i] == parent.node()){parentIdx = i;}
      }
      div.html(
        "<b>"+parent.datum().series+"</b><br/>"+item.datum()[0][tooltipName]+"<br/>y:"+item.datum()[0].y+"<br/>y0:"+item.datum()[0].y0
      )
      .style("opacity",1)
      .style("left", (d3.event.pageX - 80) + "px")
      .style("top", (d3.event.pageY - 35) + "px")
      .style("border-color",color(parentIdx))
    }

  }
  function mouseout() {
    var item = d3.select(this);
    div.style("opacity",0)
  }
  function brush(){
    y.domain(brushable.empty() ? [0,maxY] : brushable.extent());
    svg.select(".y.axis").call(yAxis);
    svg.selectAll(".series").selectAll("rect")
    .attr("y", function(d) { return y(d[0].y0 + d[0].y) })
    .attr("height",function(d) {return d3.max([ y(d[0].y0)-y(d[0].y0 + d[0].y),1]) })
  }
  function brushEnd() {

  }
  function drawLines(){
    svg.selectAll(".series").selectAll("rect")
      .style("display",'none')
      .style("opacity",0)
    svg.selectAll(".series").select("path.line")
      .style("display",'')
      .transition().duration(duration)
      .style("opacity",1)
      
  }
  function drawStack(){
    svg.selectAll(".series").select("path.line")
      .style("display",'none')
      .style("opacity",0)
    svg.selectAll(".series").selectAll("rect")
      .style("display",'')
      .transition().duration(duration)
      .style("opacity",1)
  }
  //Draw multiple X axes
  function drawXAxes(){
    // Each multiAxis is translated slightly right
    // Setup the translate values
    var bandWidth = XmultiDomains[0].rangeBand(); // get the bandwidth
    var transStep = bandWidth/(XmultiDomains.length+1); // break the band into pieces
    transVal = bandWidth/2 // Add half a bandwidth to start at right end
    XmultiAxis = XmultiDomains.map(function(x,i){
      // x-Axis - rotated text from : http://www.d3noob.org/2013/01/how-to-rotate-text-labels-for-x-axis-of.html
      transVal -= transStep;
      xAxis = d3.svg.axis().scale(x)
      svg.append("g").attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .selectAll("text")
        .style("fill",function(d){
          return color(i);
        })
        .style("text-anchor", "end")
        .style("font-size",fontSize+"px")
        .style("font-family","Courier")
        .attr("dx", "-.8em")
        .attr("dy", ".15em")
        .attr("transform", "rotate(-65) translate("+transVal/2+","+transVal+")")
    })
  }
  //Draw the series
  createLegend = function() {
   var keys, legendG, legendHeight, BoxSpace, boxHeight, topPadding;
   boxDim = 20;
   topPadding = 0;
   BoxSpace = 40;
   var columnCount = 4;
   container = document.getElementById(legendId);
   legendWidth = container.scrollWidth*.95;
   var keyOffset = Math.floor(legendWidth/columnCount);
   legendHeight = topPadding + (Math.ceil(data.length/columnCount))*BoxSpace
   legend = d3.select("#"+legendId).append("svg").attr("width", legendWidth).attr("height", legendHeight);
   legendG = legend.append("g").attr("class", "panel");
   keys = legendG.selectAll("g").data(data).enter().append("g").attr("transform", function(d, i) {
     var iMod = i%columnCount;
     var modOffset = (iMod*keyOffset)+5;
     return "translate(" + modOffset + "," + (topPadding + (BoxSpace * Math.floor(i/columnCount))) + ")";
   });

   keys.append("rect").attr("width", boxDim).attr("height", boxDim ).attr("rx", 4).attr("ry", 4).attr("fill", function(d,i) {
     return color(i);
   });

   return keys.append("text").text(function(d) {
     return d.series;
   }).attr("text-anchor", "left").attr("dx", "2.3em").attr("dy", "1.3em");
  };
  //Request and display data
  chart.load = function(path){
    d3.json(path,display);
  }
  chart.render = function(data){
    display(null,data);
  }
  
  transitionTo = function(name) {
    if (name === "stack") {
      drawStack();
    }
    if (name === "line") {
      drawLines();
    }
  };
  
  //display the data
  var display = function(error, rawData) {
    var g, requests;
    data = rawData
    //Force data to numbers
    data.forEach(function(s) {
      s.values.forEach(function(d) {
        d.y = parseFloat(d.y);
      });
    });
    var highlight_id = rawData.highlight
    //setup click event
    d3.selectAll("."+switchClass).on("click", function(d) {
      var id;
      d3.event.preventDefault();
      id = d3.select(this).attr("id");
      return transitionTo(id);
    });
    //Get longest label
    var maxLabel = d3.max(data.map(function(item){
      return d3.max(item.values.map(function(value){
        return value.x.length
      }));
    }))
    // Setup margins
    var m = config.margins || [0, 60, 20, 80]; // margins
    // Add label margin - 0.5 is rough aspect ratio estimate for font
    m[2] += maxLabel*fontSize*0.5
    width = selection.property('scrollWidth') - m[1] - m[3];
    height = selection.property('scrollHeight') - m[0] - m[2];
    // Setup X domains
    XmultiDomains = data.map(function(item){
      var cat = item.values.map(function(d){return d.x})
      //Setup the range band scale
      return d3.scale.ordinal().domain(cat).rangeBands([0,width],0.25,0.25)
    })
    // Setup X domains
    XmultiLineDomains = data.map(function(item){
      var cat = item.values.map(function(d){return d.x})
      //Setup the range band scale
      return d3.scale.ordinal().domain(cat).rangePoints([0,width],1)
    })
    lines = XmultiLineDomains.map(function(x){
      return d3.svg.line()
      .x(function(d,i) { return x(d.x); })
      .y(function(d,i) { return y(d.y); });
    });
    stack = d3.layout.stack()
    .values(function(d) {
      return d.values;
    })
    .offset("zero")
    .order("reverse");
    stack(data);
    //Setup Y domain
    maxY = d3.max(data[0].values.map(function(d) {
      return d.y0 + d.y;
    }))
    y = d3.scale.linear()
      .domain([0, maxY])
      .range([height,5]);
    brushY = d3.scale.linear()
      .domain([0, maxY])
      .range([height,5]);
    
    var plotWidth = width+ m[1] + m[3];
    var plotHeight = height + m[0] + m[2];
    // Add SVG element
    svg = selection.append("svg")
      .attr("width", plotWidth)
      .attr("height", plotHeight)
    .append("g")
      .attr("transform", "translate(" + m[3] + ","+m[0]+")")
    //zoomable rect for brushing
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
    yAxis = d3.svg.axis().scale(y).ticks(4).orient("right");
    svg.append("g").attr("class", "y axis")
      .attr("transform", "translate("+(width+10)+",0)")
      .call(yAxis)
    brushAxis = d3.svg.axis().scale(brushY).ticks(4).orient("left");
    svg.append("g").attr("class", "y brush")
      .attr("transform", "translate(-10,0)")
      .call(brushAxis)
      .call(brushable)
      .selectAll("rect")
        .attr("x", -10)
        .attr("width", 20);

    // Build the domain dynamically
    // We want evenly spaced steps for each color value
    var step = Math.ceil(data.length / 8)
    var domainArray = []
    var curValue = 0;
    while(curValue < data.length){
      curValue += step
      domainArray.push(curValue);
    }
    // Setup the color scale
    color = d3.scale.linear().domain(domainArray).interpolate(d3.interpolateRgb).range(colorbrewer.Dark2[8])
    drawXAxes();

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
    svg.selectAll(".series").select("path.line")
      .attr("d", function(d,i) { return lines[i](d.values)})
      .style("stroke",function(d,i){ return color(i) })
      .style("stroke-width",3)
      .attr("id",function(d){return "i"+d.id})
      .on("mouseover", mouseover)
      .on("mouseout", mouseout)
      .style("display",'none')
   // Add rects to each series
    var series = svg.selectAll(".series")
      .style("fill",function(d,i){ return color(i) })
      .style("stroke","#777")
      .attr("id",function(d){return "i"+d.id})
    series.selectAll("rect")
      .data(function(d,i){return d.values.map(function(v){return [v,i];}) })
      .enter().append("rect")
      .attr("x",function(d){return XmultiDomains[d[1]](d[0].x); })
      .attr("y",function(d){return y(d[0].y0 + d[0].y)})
      .attr("width",function(d){return XmultiDomains[d[1]].rangeBand();})
      .attr("height",function(d){return y(d[0].y0)})
      .on("mouseover", mouseover)
      .on("mouseout", mouseout)
      .style("display",'none')
      
    createLegend();
    drawLines();
  };
  
  return chart;
};