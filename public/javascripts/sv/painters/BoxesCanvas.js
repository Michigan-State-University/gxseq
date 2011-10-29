/*
 * Class for displaying overlapping boxes so that they do not collide
 */

Ext.define('Sv.painters.BoxesCanvas', {
  extend : 'Sv.painters.DataCanvas',
  boxHeight : 10,
	boxHeightMax : 24,
	boxHeightMin : 1,
	boxSpace : 1,
	initComponent : function(){
	  this.callParent(arguments);
	},
	paint : function(){
	  var self = this;
	  this.clear();
		
		var width = this.getWidth();
		var height = this.getHeight();
		var region = this.getRegion();
		var brush = this.getBrush();
		var series = this.series.getAll();
		var flippedX = this.isFlippedX();
		var flippedY = this.isFlippedY();
		var h = self.boxHeight * this.getScaler();
		
		if (h > self.boxHeightMax) h = self.boxHeightMax;
		if (h < self.boxHeightMin) h = self.boxHeightMin;
		
		for (var name in series) //series?
		{
			var boxes = series[name];
			
			this.levelize(boxes);

			Ext.each(boxes, function(box)
			{
				if (!self.groups.active(box.cls)) return true;
			
				var w = box.w;
				var x = flippedX ? width - box.x - w : box.x;	
				var y = box.level * (h + self.boxSpace);

				y = flippedY ? y : height - y - h;

				if (x + w < region.x1 || x > region.x2) return;
				if (y + h < region.y1 || y > region.y2) return;

				self.paintBox(box.cls, x, y, w, h);
			});
		}
	},
	//Assign levels to the boxes (assumes they are all the same height)
	levelize : function(boxes)
	{
	  var self = this;

		if (!boxes || !(boxes instanceof Array)) return;
		var inplay = new AnnoJ.Helpers.List();
		var max = 0;
				
		Ext.each(boxes, function(box)
		{
			self.groups.add(box.cls);
			if (!self.groups.active(box.cls)) return true;
	    box.level = 0;			
			if (box.x1 == undefined) box.x1 = box.x;
			if (box.x2 == undefined) box.x2 = box.x + box.w;

			var added = false;
			
			//Remove out of play elements
			for (var node=inplay.first; node; node=node.next)
			{
				if (node.value.x2 <= box.x1)
				{
					inplay.remove(node);
				}
			}
			
			//Assign the box a level
			for (var node=inplay.first; node; node=node.next)
			{
				if (box.level < node.value.level)
				{
					inplay.insertAfter(node.prev, box);
					added = true;
					break;
				}
        		box.level ++;
				max = Math.max(max, box.level);
			}
			
			//If no place was found to add the div, then add it to the end
			if (!added) inplay.insertLast(box);
		});
		return max;
	},
	
})