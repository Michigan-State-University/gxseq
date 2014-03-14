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
    	var absMax = 0;
      var madScore;
      var median;
      var dataLookup = [];
    	this.getData = function() {return data;};
    	//Set the data for this histogram from an array of points
    	this.setData = function(series){data = series;};
    	this.setAbsMax = function(m){absMax = m;};
      this.getAbsMax = function(){return absMax;}
    	this.setColor = function(value){self.color = value};
    	this.setMad = function(value){madScore = value};
    	this.getMad = function(){return madScore;}
    	this.setMedian = function(value){median = value};
    	this.getMedian = function(){return median;}
    	//Create the tooltip
    	var tooltip = document.createElement('DIV');
      tooltip.style.position = "absolute";
      tooltip.style.border="1px solid black";
      tooltip.style.padding="2px";
      tooltip.style.backgroundColor='white';
      tooltip.style.display='none';
      tooltip.style.zIndex='5';
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
        
        //Draw y axis grid
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
        
        //draw breakpoints
        brush.setLineDash([2,3]);
        
        //draw cutoff
        var mad2 = halfH-Math.round( (((2*madScore)+median)/absMax) * halfH * scaler);
        var mad = halfH-Math.round( ((madScore+median)/absMax) * halfH * scaler);
        var nmad = halfH-Math.round( ((median-madScore)/absMax) * halfH * scaler);
        var nmad2 = halfH-Math.round( ((median-(2*madScore))/absMax) * halfH * scaler);
        
        // brush.beginPath();
        // brush.moveTo(1,mad2);
        // brush.lineTo(width,mad2);
        // brush.strokeStyle='#30CC24';
        // brush.stroke();
        // 
        // brush.beginPath();
        // brush.moveTo(1,mad);
        // brush.lineTo(width,mad);
        // brush.strokeStyle='#B2B246';
        // brush.stroke();
        // 
        // brush.beginPath();
        // brush.moveTo(1,nmad);
        // brush.lineTo(width,nmad);
        // brush.strokeStyle='#8A2BE2';
        // brush.stroke();
        // 
        // brush.beginPath();
        // brush.moveTo(1,nmad2);
        // brush.lineTo(width,nmad2);
        // brush.strokeStyle='red';
        // brush.stroke();

        brush.setLineDash(linedash);
        brush.closePath();
        
        //Draw datapoint line
        brush.lineWidth=2;
        var prevColor = self.getColor(data[0].y)
        var prevPoint = [0,halfH-Math.round((data[0].y/absMax) * halfH * scaler)]
        Ext.each(data, function(datum)
        {
          // Setup
          var thisColor = self.getColor(datum.y)
          var h = Math.round( (datum.y/absMax) * halfH * scaler);
          var x = datum.x;
          var thisPoint = [x,halfH-h]
          
          var gradient=brush.createLinearGradient(prevPoint[0],prevPoint[1],thisPoint[0],thisPoint[1]);
          gradient.addColorStop(0, prevColor);
          gradient.addColorStop(1, thisColor);
          
          // render
          brush.beginPath();
          brush.moveTo(prevPoint[0],prevPoint[1]);
          brush.lineTo(thisPoint[0],thisPoint[1]);
          brush.strokeStyle=gradient;
          brush.stroke();
          brush.closePath();
          
          //store for later
          prevColor = thisColor;
          prevPoint = thisPoint;
          dataLookup[x]=[datum.y.toFixed(2),h]
        });
        
        //Setup tooltip events
        var container=this.getContainer();
        container.appendChild(tooltip)
        container.on("mousemove",function(event){
          if(event.toElement==tooltip){return;}
          //move up to find datapoint
          var x = event.layerX
          for(x;x<dataLookup.length;x++){
            if(dataLookup[x]){break;}
          }
          if(!dataLookup[x]){return;}
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
    },
    getColor: function(y){
      var madScore = this.getMad();
      var median = this.getMedian();
      var c = ''
      if(y > (2*madScore)+median){
        c='#30CC24'
      }else if(y > madScore+median){
        c='#B2B246'
      }else if(y > median-madScore){
        c='#333333'
      }else if(y > median-(2*madScore)){
        c='#8A2BE2'
      }else{
        c='red'
      }
      return c;
    }
});

