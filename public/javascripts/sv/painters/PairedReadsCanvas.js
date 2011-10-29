/*
 * Class for displaying short DNA reads as non-overlapping boxes. Shows sequence when zoomed in close
 */
var PairedReadsCanvas = function(userConfig)
{
	var self = this;
	var data = [];
	
	PairedReadsCanvas.superclass.constructor.call(self, userConfig);

	var defaultConfig = {
		boxHeight : 8,
		boxHeightMax : 24,
		boxHeightMin : 1,
		boxBlingLimit : 5
	};
	Ext.apply(self.config, userConfig, defaultConfig);
	
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
	
	//Draw points using a specified rendering class
	this.paint = function()
	{
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
		var e1 = 0;
		var e2 = 0;
		var h = Math.round(self.config.boxHeight * scaler);

		if (h < self.config.boxHeightMin) h = self.config.boxHeightMin;
		if (h > self.config.boxHeightMax) h = self.config.boxHeightMax;
				
		//Levelize the reads and get the max visible level (used for a shortcut later)
		var max = this.levelize(data);
		var maxLevel = Math.ceil(region.y2 / (h + self.config.boxSpace));
		
		Ext.each(data, function(read)
		{
			self.groups.add(read.cls);
			if (!self.groups.active(read.cls)) return;
			if (read.level > maxLevel) return;
			if (read.multi && !self.config.showMultis) return;
			
			w = read.w;
			e1 = read.e1;
			e2 = read.e2;
			x = flippedX ? width - read.x - read.w : read.x;
			y = read.level * (h + self.config.boxSpace);
			y = flippedY ? y : height - 1 - y - h;

			if (x + w < region.x1 || x > region.x2) return;
			if (y + h < region.y1 || y > region.y2) return;
			
			//Paint the box
			self.paintBox(read.cls, x, y, e1, h);
			self.paintBox(read.cls + '_spacer', x+e1, y, w-(e1+e2), h);
			self.paintBox(read.cls, x+w-e2, y, e2, h);
			
			if (read.seqA)
			{
				letterize(brush, read.seqA, x, y, e1, h, container);
				letterize(brush, read.seqB, x+w-e2, y, e2, h, container);
			}
		});
	};
	
	function letterize(brush, sequence, x, y, w, h, container)
	{
		var clean = "";
		var length = sequence.length;
		var letterW = AnnoJ.bases2pixels(1);
		var readLength = length * letterW;
		
		for (var i=0; i<length; i++)
		{
			var letter = sequence.charAt(i);

			switch (letter)
			{
				case 'A': break;
				case 'T': break;
				case 'C': break;
				case 'G': break;
				case 'N': break;
				case 'a': letter = 'A'; break;
				case 't': letter = 'T'; break;
				case 'c': letter = 'C'; break;
				case 'g': letter = 'G'; break;
				default : letter = 'N';
			}
			clean += letter;

			var letterX = x + (i * letterW);
			
			if (letterW < 5 || h < self.config.boxBlingLimit)
			{
				brush.fillStyle = self.styles.get(letter).fill;
				brush.fillRect(letterX, y, letterW, h);
			}
			else
			{
				self.paintBox(letter, letterX, y, letterW, h);
			}
		};
	};
};
Ext.extend(PairedReadsCanvas,BoxesCanvas,{})
