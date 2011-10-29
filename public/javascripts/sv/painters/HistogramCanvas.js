/*
 * Class for a histogram plot
 */
Ext.define('Sv.painters.HistogramCanvas',{
    extend : 'Sv.painters.DataCanvas',
    initComponent : function(){
        this.callParent(arguments);
        var self = this;
    	var data = {};
    	var absMax = 0;
    	var color = "black"

    	this.getData = function() {return data;};
    	//Set the data for this histogram from an array of points
    	this.setData = function(series){data = series;};

    	this.setAbsMax = function(m){absMax = m;};

    	this.setColor = function(value){color = value;};

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
    		var flippedX = this.isFlippedX();
    		var flippedY = this.isFlippedY();

    		if (scaler == 0) return;
    		if(absMax ==0) return;
    		//Fix color (string to hex)
    		if(color.match(/^\d+$/))
    		{
    		    color = "#"+color
    		}

    		brush.fillStyle = color;
    		var x,y,h,w,text;
    		Ext.each(data, function(datum)
    		{	

    			if(flippedY){
    				if(datum.y >= 0) return;
    				h = Math.round( ((-datum.y)/absMax) * height * scaler );
    				y = 0;
    			}
    			else{
    				if(datum.y <= 0) return;
    				h = Math.round( (datum.y/absMax) * height * scaler);
    				y = height - h - 1;					
    			}

    			//clip boundaries
    			if (h >= height)
    			{
    				y = 0;
    				h = height-1;
    			}

    			w = datum.w || 1;

    			//var x = flippedX ? width - datum.x - w : datum.x;
    			x = datum.x;
    			if (x + w < 0 || x > width) return;			

    			brush.fillRect(x, y, w, h);
    		});

    		//Draw some more track info
    		brush.fillStyle = "#000000";

    	};
    }
});

