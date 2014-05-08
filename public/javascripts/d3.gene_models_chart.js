d3.gene_models_chart = function(config){
  var chart = {};
  var containerId, data, g, geneLevel, height, splitHeight, svg, width, x, xAxis, y, yAxis, minX, maxX,maxLevel,maxSplitLevel;
  data = null;
  var isStacking = true;
  containerId = config.container;
  var selection = d3.select(containerId);
  width = selection.property('scrollWidth');
  var xMin = config.min;
  var xMax= config.max;
  var m = config.rMargin || 25;
  var axismR = 10;
  var axismB = 25;
  var mL = config.lMargin || 10;
  width = width-(m+mL)
  var modelHeight = 15;
  var featureIds = config.featureIds;
  // Stacking event
  d3.select("#stacking").on('click',function(){
      d3.event.preventDefault();
      toggleStacking()
    })    
  // Add the tooltip
  var div = selection.append("div")
    .attr("class", "tooltip")
    .style("opacity", 0);
  //Setup Tooltip
  function featureMouseover(data,idx) {
    if(isStacking){return};
    var item = d3.select(this);
    //assumes the first item in values array is Gene
    //values array created by d3.nest using gene_id
    var html="<b>"+item.datum()[3]+"</b>"
    html+="<br/><b>Start:</b>"+item.datum()[4]
    html+="<br/><b>End:</b>"+(item.datum()[4]+item.datum()[5]-1)
    div.html(html)
    .style("opacity",0.8)
    .style("left", (d3.event.pageX - 100) + "px")
    .style("top", (d3.event.pageY - 50) + "px")
  };
  function geneMouseover(data,idx) {
    if(!isStacking){return};
    var item = d3.select(this);
    var html="<b>Locus:</b>"+item.datum().values[0][8]
    html+="<br/><b>Gene:</b>"+item.datum().values[0][10]
    div.html(html)
    .style("opacity",0.8)
    .style("left", (d3.event.pageX - 80) + "px")
    .style("top", (d3.event.pageY - 35) + "px")
  };
  function mouseout() {
    var item = d3.select(this);
    div.style("opacity",0)
  };
  //Request and display data
  chart.load = function(path){
    d3.json(path,display);
  };
  //Render inline data
  chart.render = function(data){
    display(null,{'data':data});
  };
  var display = function(error, rawData) {
    data = rawData.data;
    // sort by left location then gene_id
    data.sort(function(a,b){
      a_id = (a[0]==null?a[1]:a[0])
      b_id = (b[0]==null?b[1]:b[0])
      if(a[4]==b[4]){
        return a_id-b_id
      }else{
        return a[4]-b[4]
      }
    })
    // levelize genes
    var maxRight = [0];
    maxLevel = 1;
    data.forEach(function(item){
      if(item[3]!='gene')return;
      var level = 0;
      left = item[4];
      right = item[4]+item[5];
      while(item.level==null){
        if(maxRight[level]==null){
          maxRight[level] = right;
          item.level = level;
          maxLevel+=1;
        }
        if(left > maxRight[level]){
          maxRight[level] = right;
          item.level = level;
        }
        level+=1
      }

    })
    //sort by gene_id, type, then location
    data.sort(function(a,b){
      a_id = (a[0]==null?a[1]:a[0])
      b_id = (b[0]==null?b[1]:b[0])
      
      if(a_id==b_id){
        //same id
        if(a[3]==b[3]){   
          //same type, sort location
          return a[4]-b[4]
        }else{
          //sort type
          return sortTypes(a,b)
        }
      }else{
        //sort id
        return a_id-b_id
      }
    })
    //levelize everything. 
    maxSplitLevel=1;
    geneRight=0;
    geneId=0;
    maxRight=[0];
    maxGeneRight=[0];
    levelGene=[];
    data.forEach(function(item){
      var level = 0;
      var left = item[4];
      var right = item[4]+item[5];
      if(item[3]=='gene'){geneRight=right}
      var gid = (item[0]==null?item[1]:item[0])
      while(item.splitlevel==null){
        if(maxRight[level]==null){
          maxRight[level] = right;
          maxGeneRight[level] = geneRight;
          item.splitlevel = level;
          levelGene[level]=gid;
          maxSplitLevel+=1;
        }
        if(gid==levelGene[level]){
          if(left > maxRight[level]){
            maxRight[level] = right;
            maxGeneRight[level] = geneRight;
            item.splitlevel = level;
          }
        }else{
          if(left > maxGeneRight[level]){
            maxRight[level] = right;
            maxGeneRight[level] = geneRight;
            levelGene[level]=gid;
            item.splitlevel = level;
          }
        }
        level+=1;
      }

    })
    //Group the elements and sort
    var nestedData = d3.nest()
      .key(function(d) { return (d[0]==null)?d[1]:d[0]; })
      .sortValues(function(a,b){return sortTypes(a,b)})
      .entries(data);
    //set height
    height = axismB+(modelHeight+3)*(maxLevel+1)
    splitHeight = axismB+(modelHeight+3)*(maxSplitLevel+1)
    //Setup scales
    x = d3.scale.linear()
      .domain([xMin,xMax])
      .range([0, width-axismR]);
    y = d3.scale.linear()
      .domain([0, maxLevel+1])
      .range([height-axismB,0]);
    // Add SVG element
    svg = selection.append("svg")
      .attr("id","mainSVG")
      .attr("width", width)
      .attr("height", height)
      .append("g")
      .attr("transform", "translate("+mL+",0)")
    // X-Axis
    xAxis = d3.svg.axis().scale(x);
    svg.append("g").attr("class", "x axis gene")
      .attr("transform", "translate(0," + (height-axismB) + ")")
      .call(xAxis);
    //bind data
    features = svg.selectAll(".feature").data(nestedData).enter()
    //Setup the clipping for strands
    features.append("clipPath")
      .attr("id",function(d,i){return "clip"+i;})
      .append("polygon")
        .attr("points",function(d){
          gene = d.values[0]
          var x1 = x(gene[4])
          var x2 = x(gene[4]+gene[5])
          var y1 = y(getLevel(gene))
          var y2 = y1+modelHeight
          var half = Math.round(y1+modelHeight/2)
          var inx = x1+6
          var inx2 = x2-6
          if(gene[2]=='+'){
            return x2+" "+half+","+inx2+" "+y2+","+x1+" "+y2+","+x1+" "+y1+","+inx2+" "+y1+","+x2+" "+half
          }else{
            return x1+" "+half+","+inx+" "+y1+","+x2+" "+y1+","+x2+" "+y2+","+inx+" "+y2+","+x1+" "+half
          }
        })
    //Add group with clipping for each item
    group = features.append("svg:g")
      .attr("class", "feature")
      .attr("clip-path",function(d,i){return"url(#clip"+i+")"})
      .on("mouseover", geneMouseover)
      .on("mouseout", mouseout);
    //Draw each item
    var features = group.selectAll(".feature")
    .data(function(d){return d.values})
    .enter()
    features.append("image")
      .attr("class","feature_image")
      .attr("x", function(d){return x(d[4])})
      .attr("y", function(d){return y(getLevel(d))})
      .attr("width", function(d){return d3.max([x(d[4]+d[5])-x(d[4]),1])})
      .attr("height", modelHeight)
      .attr("preserveAspectRatio",'none')
      .attr("xlink:href", function(d){return getImage(d[3])})
      .on("mouseover", featureMouseover)
      .on("mouseout", mouseout)
  };
  // Sort: gene < mRNA < cds/other
  var sortTypes = function(a,b){
    if(a[3]==b[3])
      return 0
    if(a[3]=='gene')
      return -1
    if(b[3]=='gene')
      return 1
    if(a[3]=='mRNA')
      return -1
    if(b[3]=='mRNA')
      return 1
    else
      return 0
  }
  //Transition items to new state if isStacking changes
  var update = function(){
    
    if(!isStacking){
      //Change svg height
      d3.select('#mainSVG').transition().duration(750).attr("height",splitHeight)
      y.domain([0, maxSplitLevel+1]).range([splitHeight-axismB,0])
      d3.select("g .x.axis.gene").transition().duration(750).call(xAxis).attr("transform", "translate(0," + (splitHeight-axismB) + ")")
      //Unclip
      svg.selectAll("g .feature").attr("clip-path","none")
    }else{
      //Change svg height
      d3.select('#mainSVG').transition().duration(750).attr("height",height)
      y.domain([0, maxLevel+1]).range([height-axismB,0])
      d3.select(".x.axis.gene").transition().duration(750).call(xAxis).attr("transform", "translate(0," + (height-axismB) + ")")
    }
    //Move Items
    svg.selectAll(".feature_image").transition().duration(750)
    .attr("y", function(d){return y(getLevel(d))})
    .each("end",function(d,i){
      if(i===1 && isStacking){
        //re-clip after transition end
        svg.selectAll("g .feature").attr("clip-path",function(d,i){return"url(#clip"+i+")"})
      }
    })
  }
  var getLevel = function(item){
    if(isStacking){
      if(item[3]=='gene'){geneLevel = item.level}
      return geneLevel+1
    }else{
      return item.splitlevel+1
    }
  }
  var getImage = function(type){
    switch(type){
      case "gene":
        return "/images/models/bar.gif";
      case "mRNA":
        return "/images/models/red.gif";
      case "CDS":
        return "/images/models/green.gif" 
    }
  }
  var toggleStacking = function(){
    isStacking = !isStacking
    update()
  }
  return chart;
};