/*
* Class for a line chart
  Expects data as percentage from 0.0-1.0
*/
Ext.define('Sv.painters.LineChartCanvas',{
  extend: 'Sv.painters.DataCanvas',
  boxHeight : 20,
  boxHeightMax : 24,
  boxHeightMin : 1,
  boxBlingLimit : 6,
  boxSpace : 1,
  initComponent : function(){
    this.callParent(arguments)
    var self = this;
    var data = [];
    var max = 0;

    //Set the data for this histogram from an array of points
    this.setData = function(reads)
    {
      if (!(reads instanceof Array)) return;
      Ext.each(reads, function(read)
      {
        self.groups.add(read.cls);
      });
      data = reads;
    };

    this.getMax = function()
    {
      return max;
    };

    this.normalize = function(max)
    {
      for (var name in data)
      {
        Ext.each(data[name], function(datum)
        {
          datum.y /= max;
        });
      }		
    };

    this.paint = function()
    {
      this.clear();

      if (!data || data.length == 0) return;
      var container = this.getContainer();
      var canvas = this.getCanvas();
      var region = this.getRegion();
      if(!region) return;
      var width = this.getWidth();
      var height = this.getHeight();
      var brush = this.getBrush();
      var scaler = this.getScaler();
      var flippedX = this.isFlippedX();
      var flippedY = this.isFlippedY();

      var x = 0;
      var y = 0;
      var w = 0;
      var e = 0;
      var h = Math.round(self.boxHeight * scaler);

      if (h < self.boxHeightMin) h = self.boxHeightMin;
      if (h > self.boxHeightMax) h = self.boxHeightMax;

      self.paintBox('line',0,height*0.25,width,1);            
      self.paintBox('line',0,height*0.75,width,1);
      brush.fillStyle = "rgb(100,100,200)";
      if(height > 40)
      {
        brush.fillText('25%',10,(height*0.75)+5)
        brush.fillText('75%',10,(height*0.25)+5)
      }
      var col = 0;
      Ext.each(data, function(read)
      {   
        var dif = 0
        x = read.x
        if(x<0)
        {
          dif = 0-x;
          x=0;
        }
        w = read.w - dif
        if(x+w > width)
        w = (width-x)
        var containerDiv = document.createElement('DIV');
        containerDiv.setAttribute('id','canvasContainerDiv_'+read.x)
        containerDiv.style.width = w+"px";
        containerDiv.style.height = height+"px";
        containerDiv.style.left = x+"px";
        containerDiv.style.top = "0px";
        containerDiv.style.position = "absolute";
        // containerDiv.style.border ="1px solid rgb(250,"+col+","+(250-col)+")"
        container.appendChild(containerDiv);

        brush.strokeStyle="rgb(130,130,210)";
        brush.beginPath();
        paintContent(read.seqlist,read.x,brush,read.bases,read.pixels,height,containerDiv,x,width);
        brush.stroke();
        col += 100;
      });
    };

    function paintContent(GCList,xStartLocation,brush,bases,pixels,height,containerDiv,x,width){
      var newDivs = [];
      event_ids = [];
      for (var n=0; n<GCList.length; n++)
      {   
        step = (GCList[n][1] * pixels / bases)
        // Only draw points / divs that fall in the viewable window adjusted for current zoom
        if(xStartLocation >= (-step) && xStartLocation <= (width+step)){
          y = (height - (height * GCList[n][0]))            
          // ----mouseover--- //
          newDivs.push("<div id="+xStartLocation.toFixed(1)+"_point_data style='display:none; padding:2px; background:white; border-radius:6px; border:1px solid rgb(150,200,250); left: "+((xStartLocation-63)-x)+"px; top: "+(y-10)+"px; position: absolute;'>"+(GCList[n][0]*100).toFixed(2)+"%"+"</div>");
          newDivs.push("<div id="+xStartLocation.toFixed(1)+"_point style='width:16px; height:16px; left: "+((xStartLocation-8)-x)+"px; top: "+(y-8)+"px; cursor: pointer; position: absolute;'></div>");
          event_ids.push(xStartLocation.toFixed(1)+"_point")	

          brush.lineTo(xStartLocation, y);      
        }
        xStartLocation += step;
      };

      // append all of the divs at once
      containerDiv.innerHTML+=newDivs.join("\n");
      for(i=0;i<event_ids.length;i++)
      {
        if(Ext.get(event_ids[i])){
          Ext.get(event_ids[i]).addListener('mouseover', hoverPoint);   
          Ext.get(event_ids[i]).addListener('mouseout', leavePoint);
        }
      }           
    }

    function hoverPoint(event, srcEl, obj)
    {
      var el = Ext.get(srcEl);
      Ext.get(el.id+"_data").show();
      el.addCls("small_button")
    };
    function leavePoint(event, srcEl, obj)
    {
      var el = Ext.get(srcEl);
      Ext.get(el.id+"_data").hide();
      el.removeCls("small_button")
    };
  }
});
