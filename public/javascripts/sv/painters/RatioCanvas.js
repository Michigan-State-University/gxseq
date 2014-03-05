/*
 * Class for a histogram plot
 */
Ext.define('Sv.painters.RatioCanvas',{
    extend : 'Sv.painters.DataCanvas',
    color : 'black',
    setStyle : function(newStyle){
      this.style=newStyle;
    },
    initComponent : function(){
      this.callParent(arguments);
      var self = this;
    	var data = [];
    	var dataLookup = [];
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
    		dataLookup=[];
    		if (!data || data.length == 0) return;
    		var region = this.getRegion();
        if(!region) return;
    		var brush = this.getBrush();
    		var width = this.getWidth();
    		var height = this.getHeight();
        var absMax = this.getAbsMax();
    		if(absMax == 0) return;
        
    		//Start Path
        var halfH= height/2
        pi2 = 2*Math.PI;
        brush.beginPath();
        brush.strokeStyle='grey'
        linedash = brush.getLineDash();
        brush.setLineDash([3,2]);
        brush.moveTo(1,halfH)
        brush.lineTo(width-1,halfH)
        brush.stroke();
        
        brush.setLineDash([1,3]);
        var scaler = .75
        var fullHalf = absMax/scaler
        brush.beginPath();
        for(var step=20; step<halfH;step+=20){
          var val = ((fullHalf/halfH)*step).toFixed(2)
          
          brush.moveTo(1,halfH+step)
          brush.lineTo(width,halfH+step)
          brush.fillText('-'+val,5,halfH+step+2)
          
          brush.moveTo(1,halfH-step)
          brush.lineTo(width,halfH-step)
          brush.fillText(val,5,halfH-step+2)
        }
        brush.stroke();
        brush.setLineDash(linedash);

        brush.closePath();
        brush.beginPath();
        brush.lineWidth=1;
        brush.strokeStyle='black'
        //initial height
        brush.moveTo(0,halfH-Math.round((data[0].y/absMax) * halfH * scaler))
        Ext.each(data, function(datum)
        {
          // Set height
          var h = Math.round( (datum.y/absMax) * halfH * scaler);
          var x = datum.x;
          brush.lineTo(x,halfH-h);
          brush.stroke();
          //store for render
          dataLookup[x]=[datum.y.toFixed(2),h]
        });
        
        //Tooltip
        var tooltip = document.createElement('DIV');
        tooltip.style.position = "absolute";
        tooltip.style.border="1px solid black";
        tooltip.style.padding="2px";
        tooltip.style.backgroundColor='white';
        tooltip.style.display='none';
        tooltip.style.zIndex='5';
        var container=this.getContainer();
        container.appendChild(tooltip)
        container.on("mousemove",function(event){
          if(event.toElement==tooltip){return;}
          //console.log(event)
          //move up to find datapoint
          var x = event.layerX
          for(x;x<dataLookup.length;x++){
            if(dataLookup[x]){break;}
          }
          //update div with data
          var val = dataLookup[x][0];
          var h = dataLookup[x][1];
          tooltip.style.display='';
          tooltip.innerHTML=val;
          tooltip.style.left=(x)+'px';
          tooltip.style.top=(halfH-h)+'px';
        })
        container.on("mouseout",function(event){
            if(event.toElement==tooltip){return;}
            tooltip.style.display='none';
        })
    	};
    }
});

