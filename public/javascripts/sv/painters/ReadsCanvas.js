/*
 * Class for displaying short DNA reads as non-overlapping boxes. Shows sequence when zoomed in close
 */
Ext.define('Sv.painters.ReadsCanvas',{
  extend: 'Sv.painters.BoxesCanvas',
  boxHeight : 12,
	boxHeightMax : 24,
	boxHeightMin : 1,
	boxBlingLimit : 4,
	boxSpace : 4,
	pairedEnd : false,
	ratio : 1,
	frameBreaks : [],
	viewport : {},
	forwardColor:'#44D',
	reverseColor : '44D',
	colorBases : true,
	drawFrames: false,
	drawFrameBreaks: function(){
	  var self = this;
	  var brush = self.getBrush();
	  var region = self.getRegion();
	  var height = self.getHeight();
    brush.lineWidth = 1.0;
    Ext.each(self.frameBreaks, function(fb){
      x = Math.round((fb.x1-self.viewport.x1) * self.viewport.pixels / self.viewport.bases);
      if(x%2!=0) x+=1;
      if(x >= region.x1 && x <= region.x2)
      {
        // Draw the Frame break
        brush.fillStyle = "rgba(75,75,85,.8)";
        brush.fillRect(x,0,1,height);
        brush.fillStyle = "rgba(75,75,85,.2)";
        brush.fillRect(x-2,0,1,height);
        // Text background
        brush.fillStyle = "#EEF";
        metrics = brush.measureText(fb.msg)
        brush.fillRect(x+5,1,metrics.width+2,11);
        // Frame msg text
        brush.textAlign = "left";
        brush.fillStyle = "rgba(75,75,85,.9)";
        brush.fillText(fb.msg,x+5,9);
      }
      
      x2 = Math.round((fb.x2-self.viewport.x1) * self.viewport.pixels / self.viewport.bases);
      if(x2 >= region.x1 && x2 <= region.x2)
      {
        // Text Background
        metrics = brush.measureText(fb.msg)
        brush.fillStyle = "#EEF";
        brush.fillRect((x2-metrics.width)-5,1,metrics.width+2,11);
        // Frame msg text
        brush.fillStyle = "rgba(75,75,85,.9)";
        brush.textAlign = "right"          
        brush.fillText(fb.msg,x2-5, 9)
      }
    });
	},
  initComponent: function(){
    var self = this;
    var data;
    self.callParent(arguments);
    
    self.addEvents({
			'itemSelected' : true
		});
		
  	//Set the data for this histogram from an array of points
  	this.setData = function(reads)
  	{
  		if (!(reads instanceof Array)) return;

  		Ext.each(reads, function(read)
  		{
  			self.groups.add(read.cls);
  		});
  		data = reads;
  		//console.log("Canvas data set:"+self.id)
  	};

  	//Toggle the state of elements containing the specified class name
  	this.toggleSpecial = function(targetCls, state)
  	{
  		var list = self.groups.getList();

  		for (var cls in list)
  		{
  			if (cls.indexOf(targetCls) != -1)
  			{
  				self.groups.toggle(cls, state);
  			}
  		}
  	};
    
    //Add a new frameBreak
    this.addBreak = function(x1,x2,msg)
    {
      self.frameBreaks.push({x1 : x1, x2 : x2, msg : msg})
    };
    //Clear frameBreaks
    this.clearBreaks = function()
    {
      self.frameBreaks = [];
    };
    
    // View ratio for rendering
    this.setViewport = function(x1,x2,bases,pixels)
    {
      self.viewport = {
        x1:x1,
        x2:x2,
        bases:bases,
        pixels:pixels
      }
    };
    
  	//Draw points using a specified rendering class
  	this.paint = function()
  	{
  	  //console.log("painting from canvas:"+self.id)
  		this.clear();
  		var container = this.getContainer();
  		var canvas = this.getCanvas();
  		var region = this.getRegion();
  		var width = this.getWidth();
  		var height = this.getHeight();
  		var brush = this.getBrush();
  		var scaler = this.getScaler();
  		var flippedX = this.isFlippedX();
  		var flippedY = this.isFlippedY();
      
      if(!region) return;
      
  		var x = 0;
  		var y = 0;
  		var w = 0;
  		var e = 0;
  		
  		var h = Math.round(self.boxHeight * scaler);
      
  		if (h < self.boxHeightMin) h = self.boxHeightMin;
  		if (h > self.boxHeightMax) h = self.boxHeightMax;
  		
      // //JS will be too slow if too many divs are being drawn - use an array and innerHTML instead
      // //create div we can use to alter innerHTML
      //       var containerDiv = document.createElement('DIV');
      //       containerDiv.style.width = width+"px";
      //       containerDiv.style.height = height+"px";
      //       containerDiv.style.left = "0px";
      //       containerDiv.style.top = "0px";
      //       containerDiv.style.position = "absolute";
      //       container.appendChild(containerDiv);
      //       
      // var newDivs = [];
  		
  		var maxLevel = Math.ceil(height/h);
  		
  		// Build Image Map for click event    
      //Add an empty map 
      var readMap = document.createElement('MAP');
      readMap.setAttribute("id","#"+container.id+"map");
      readMap.setAttribute("name","#"+container.id+"map");
      container.appendChild(readMap);
      //Add an array to hold the area tags
      var mapAreas = [];
      //Add the img tag
      var mapImage = document.createElement('IMG');
      mapImage.style.width = width+"px";
      mapImage.style.height = height+"px";
      mapImage.style.left = "0px";
      mapImage.style.top = "0px";
      mapImage.style.position = "absolute";
      //An image without a src might have a border rendered by the browser. Use a 1x1 empty image instead
      mapImage.src = 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='
      //tie the img to the map
      mapImage.setAttribute("usemap","#"+container.id+"map");
      container.appendChild(mapImage);
      
      //Loop over every read
  		Ext.each(data, function(read)
  		{
  			if (read.level > maxLevel) return;
  			w = read.w;
  			//e = read.e;
  			x = flippedX ? width - read.x - read.w : read.x;
  			y = read.level * (h + ((scaler==0) ? 0 : self.boxSpace));
  			y = flippedY ? y : height - 1 - y - h;

  			if (x + w < region.x1 || x > region.x2) return;
  			if (y + h < region.y1 || y > region.y2) return;
        
        if(w>15)
        {
          //newDivs.push("<div id="+container.id+"_read_"+read.id+" data-id="+read.id+" style='width: "+w+"px; height: "+h+"px; left: "+x+"px; top: "+y+"px; cursor: pointer; position: absolute;'></div>");
          mapAreas.push("<area shape='rect' coords='"+x+","+y+","+(x+w)+","+(y+h)+"' id=model_"+read.id+" data-id="+read.id+" href='#' alt='Read Details' title='Read Details'>");
        }
        //Setup read style. TODO: allow user control of read colors
  			aw = 5
  			aw_offset = (read.level==0) ? 1 : 2
  			if(read.strand =='+')
  			{
  			  brush.fillStyle = self.forwardColor;
    			brush.fillRect(x, y, w, h);
    			//arrow point
    			self.paintBox('forward_read',x+w-aw,y-1,aw,h+aw_offset);
			  }
			  else{
			    brush.fillStyle = self.reverseColor;
    			brush.fillRect(x, y, w, h);
    			//arrow point
    			self.paintBox('reverse_read',x,y-1,aw,h+aw_offset);
			  }
  			// Loop over each child provided by data source
        Ext.each(read.children, function(child)
        {
          if(child.length>2)
          //TODO: in some places we have coupled the canvas to the viewport. This needs to be addressed
          var child_x = Math.ceil((child[1]) * self.viewport.pixels/self.viewport.bases)+x
          var child_w = Math.ceil((child[2]) * self.viewport.pixels/self.viewport.bases)
          self.paintBox(child[0],child_x,y,child_w,h)
        });

        if (read.sequence)
        {
         letterize(brush, read.sequence, x, y, w, h, container);
        }
  		});
      
      if(self.drawFrames){
        self.drawFrameBreaks();
      }
      
      // //Append all the html DIVs we created
      // containerDiv.innerHTML+=newDivs.join("\n");

      // //setup the click event
      // for(i=0;i<containerDiv.children.length;i++)
      //   Ext.get(containerDiv.children[i]).addListener('mouseup', selectItem);
      
      //click handler
      function selectItem(event, srcEl, obj)
  		{
  			var el = Ext.get(srcEl);
  			var pos = self.viewport.x1 + Math.round((self.viewport.bases / self.viewport.pixels) * (event.getX()-Ext.get(self.getContainer()).getX()))
  			self.fireEvent('itemSelected', el.dom.getAttribute('data-id'),pos);
  		};
  		
      //Append all the map areas we created
      readMap.innerHTML+=mapAreas.join("\n");
      //setup the click event
      for(i=0;i<readMap.children.length;i++){
        Ext.get(readMap.children[i]).addListener('mouseup', selectItem);
      }
  	};
    

		
  	function letterize(brush, sequence, x, y, w, h, container)
  	{
  		var length = sequence.length;
  		var letterW = Math.max(self.viewport.pixels/self.viewport.bases);
  		
  		var half = length/2;
  		var readLength = half * letterW;

  		for (var i=0; i<length; i++)
  		{
  			var letter = sequence.charAt(i);
  			
			  var cls = 'base'
			  if(self.colorBases){ 
  				switch (letter){
            case '-': cls = '';break;
            case 'n': cls = 'base_spacer';break;
            case 'D': cls = 'base_deletion';break;
            case 'a': cls = 'A_mis'; break;
            case 't': cls = 'T_mis'; break;
            case 'c': cls = 'C_mis'; break;
            case 'g': cls = 'G_mis'; break;
            case 'A': cls = 'A'; break;
            case 'T': cls = 'T'; break;
            case 'C': cls = 'C'; break;
            case 'G': cls = 'G'; break;
            case 'N': cls = 'N'; break;
    			}
    		}

  			var letterX = x + (i * letterW)
  			if ((letterW >= 5 && h >= self.boxBlingLimit && letter != '-'))
  			{
  			  self.paintBox(cls, letterX, y, letterW, h);
  			  brush.fillStyle = '#fff'
      		brush.font = 'bold '+(letterW+1)+'px'+' courier new, monospace'
  				brush.fillText(letter,letterX,y+h-1)
  			}
  		};
  	};
  }
});