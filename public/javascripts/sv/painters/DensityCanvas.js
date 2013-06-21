/*
 * Class for a histogram plot
 */
Ext.define('Sv.painters.DensityCanvas',{
    extend : 'Sv.painters.DataCanvas',
    color : 'black',
    style : 'bar',
    setStyle : function(newStyle){
      this.style=newStyle;
    },
    initComponent : function(){
        this.callParent(arguments);
        var self = this;
    	var data = [];
    	var absMax = 0;

    	this.getData = function() {return data;};
    	//Set the data for this histogram from an array of points
    	this.setData = function(series){data = series;};
    	this.setAbsMax = function(m){absMax = m;};
      this.getAbsMax = function(){return absMax;}
    	this.setColor = function(value){
    	  self.color = value
    	};
    	//Draw points using a specified rendering class
    	this.paint = function()
    	{
    		this.clear();
    		if (!data || data.length == 0) return;
    		var region = this.getRegion();
        if(!region) return;
    		var brush = this.getBrush();
    		var width = this.getWidth();
    		var height = this.getHeight();
    		var scaler = this.getScaler();
    		var flippedY = this.isFlippedY();

    		if (scaler == 0) return;
    		if(absMax == 0) return;
    		//Fix color (string to hex)
    		if(self.color.match(/^\d+$/)){self.color = "#"+self.color;}
    		//Set colors
    		brush.fillStyle = self.color;
    		brush.strokeStyle = self.color;
    		var x,y,h,w,text;
    		// get data boundaries
    		var lastX=data[data.length-1].x;
        var firstX=data[0].x
        //clip the first and last boundaries
        // if (lastX > width){lastX=width;}
        // if (firstX < 0){firstX=0;}
    		//Start Path
    		if(self.style=='area'||self.style=='line'){
          brush.beginPath();
          if(flippedY){
            brush.moveTo(lastX, 0);
            brush.lineTo(firstX,0)
          }else{
            brush.moveTo(lastX, height+1);
            brush.lineTo(firstX,height+1)
          }
        }
    		Ext.each(data, function(datum)
    		{
    		  // Set height
          if(datum.y >= 0){
            h = Math.round( (datum.y/absMax) * height * scaler);
          }else{
            h = Math.round( ((-datum.y)/absMax) * height * scaler );
          }
          // Check for reverse
    			if(flippedY){
    			  y = 0;
    			}else{
            // if(datum.y <= 0) return;
    				y = height - h - 1;					
    			}
    		  //clip boundaries
    			if (h >= height)
    			{
    				y = 0;
    				h = height-1;
    			}
          //default width
    			w = datum.w || 1;
          x = datum.x;
    			//if (x + w < 0 || x > width) return;			
    			//draw bar or move path
          if(self.style=='bar'){
            brush.fillRect(x, y, w, h);
          }else{
            if(flippedY){
              brush.lineTo(x,h)
            }else{
              brush.lineTo(x,y)
            }
          }
    		});
    		// Finish path
        if(self.style=='area'||self.style=='line'){
          if(flippedY){
            brush.lineTo(lastX, 0);
          }else{
            brush.lineTo(lastX, height+1);
          }
          if(self.style=='area'){
            brush.fill()
          }else{
            brush.stroke()
          }
        }
    	};
    }
});

