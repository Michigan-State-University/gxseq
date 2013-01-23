/*
 * Class for a DNA sequence canvas
 */
Ext.define('Sv.painters.SequenceCanvas',{
	extend : 'Sv.painters.BoxesCanvas',
	boxHeight : 20,
	boxHeightMax : 24,
	boxHeightMin : 1,
	boxBlingLimit : 6,
	boxSpace : 1,
	pairedEnd : false,
	initComponent : function(){ 
		this.callParent(arguments);
		var self = this;
		var data = [];

		//Set the data from an array of points
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

			Ext.each(data, function(read)
			{
				var groups = self.groups.getList();
				self.groups.add(read.cls);
				if (!self.groups.active(read.cls)) return;
				var letterW = AnnoJ.bases2pixels(1);
				w = read.w;
				e = read.e;
				x = read.x;
				left = (0-(x/letterW));

				if (left < 0) left = 0;

				right = Math.min(Math.ceil(width/letterW)+left,read.sequence.length);

				y = (height/2) - (h/2);
				if (x + w < region.x1 || x > region.x2) {
					return;
				}
				if(letterW > 2){
				  for (var i=left; i<=right; i++)
					{
						var letter = read.sequence.charAt(i);
						var letterX = x + (i * letterW);
						//self.paintWedge(letterX, 0, 1, y, 'line');
						self.paintBox(letter, letterX, y, letterW, h);
					};
				}else{
				  
				}
			});
		};
	}
});
