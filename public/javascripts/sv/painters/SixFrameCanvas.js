/*
 * Class for a Six Frame canvas
 */

Ext.define('Sv.painters.SixFrameCanvas',{
	extend: 'Sv.painters.BoxesCanvas',
	boxHeight : 20,
	boxHeightMax : 24,
	boxHeightMin : 1,
	boxBlingLimit : 6,
	boxSpace : 1,
	pairedEnd : false,
	showProteins : true,
	showCodons : false,
	initComponent : function(){
		this.callParent(arguments);
		var self = this;
		var data = [];

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

		//Draw points using a specified rendering class
		this.paint = function()
		{	
			self = this;
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

			var x = 0;
			var y = 0;
			var w = 0;
			var e = 0;
			var h = Math.round(self.boxHeight * scaler);

			if (h < self.boxHeightMin) h = self.boxHeightMin;
			if (h > self.boxHeightMax) h = self.boxHeightMax;


			Ext.each(data, function(read)
			{
	      // Test if we are at the upper or lower 3 frames
	  		var upper = (read.frameNum <= 3 ? true : false)
				// Test if we are an active group
				var groups = self.groups.getList();
	      self.groups.add(read.cls);
	      if (!self.groups.active(read.cls)) return;

				w = read.w;
				e = read.e;
				x = flippedX ? width - read.x - read.w : read.x;

				if(!upper){ // Lower 3 frames (4,5,6)
	        y = ((read.frameNum-4) * (h + self.boxSpace));
					if (x < region.x1 || x-w > region.x2) return; //test if we are in the region
				}
				else { // Upper three frames (3,2,1)
	        y = ((read.frameNum-1) * (h + self.boxSpace));
	        y = flippedY ? y : height - 1 - y - h;
					if (x + w < region.x1 || x > region.x2) return; //test if we are in the region
				}

				letterize_frame(brush, read.sequence, x, y, w, h, container,read.offset, width, height, upper, self);
			});
		};

		function letterize_frame(brush, sequence, x, y, w, h, container,offset, width, height, upper, self)
		{
	    // console.log("Six Frame x:"+x)
			var length = sequence.length;
			//1,2,3 etc..
			var letterW = AnnoJ.bases2pixels(1);
			var baseW = AnnoJ.pixels2bases(1);
			pixel_offset=Math.ceil(offset*letterW)
			if(letterW < 1) letterW =1;
			if(baseW < 1) baseW = 1;
			var half = Math.ceil(length/2)/baseW;
			var readLength = half * letterW;

			if(!upper)
			{
				left = Math.floor( (((x/letterW)-(width/letterW))/3)*baseW );
				if (left < 0) left = 0;
				right = Math.min( Math.ceil(((width/letterW)/3)+left+1)*baseW, length);

				for (var i=left;i<right;i++)
	    		{
					var letter = sequence.charAt(i);
					if(letter == "*") letter = "star";
					var shift = Math.ceil(((i)*letterW * 3)/baseW);
					var letterX = (x-shift) - pixel_offset
					if (self.showProteins)
					{ 
						self.paintBox("p_"+letter, letterX, y, letterW, h);
						self.paintWedgeLower(letterX, 0, 1, height, 'line');
					}
					if (self.showCodons)
					{
						if(i==left+1){
							self.paintBox('line',0,y,width,1) ; 
							self.paintBox('line',0,y+h,width,1) ;
						}
						if(letter == "star" || letter =="M"){
							self.paintBox("p_"+letter, letterX, y, letterW, h);
						}
					}	
	    		}
			}
			else 
			{ // Upper (3,2,1)
				left = Math.floor( ((0-(x/letterW))/3)*baseW );
				if (left < 0) left = 0;
				right = Math.min( Math.ceil(((width/letterW)/3)+left)*baseW,length);

				for (var i=left; i<right; i++)
				{
					var letter = sequence.charAt(i);
					if(letter == "*") letter = "star";
					var shift = Math.ceil(((i)*letterW * 3)/baseW);
					var letterX = x + shift + pixel_offset
					if (self.showProteins)
					{ 

						self.paintBox("p_"+letter, letterX, y, letterW, h);
						self.paintWedge(letterX, 0, 1, height, 'line');
					}
					if(self.showCodons)
					{
						if(i==left){
							self.paintBox('line',0,y+h-1,width,1) ; 
							self.paintBox('line',0,y-1,width,1) ;
						}
						if(letter == "star" || letter =="M"){
							self.paintBox("p_"+letter, letterX, y, letterW, h);
						}
					}
				}
			}
		};
	},
	
});
