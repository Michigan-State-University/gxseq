/*
 * Class for a histogram plot
 */
var StacksCanvas = function()
{
	StacksCanvas.superclass.constructor.call(this, arguments);

	var stacks = [];
	var letterHeight = 1;
	var letterGap = 1;

	//Provide data for the track to render
	this.setData = function(data, update)
	{
		stacks = [];
		
		Ext.each(data, function(datum)
		{
			Ext.applyIf(datum,
			{
				x : 0,
				w : 0,
				a : 0,
				t : 0,
				c : 0,
				g : 0
			});
			stacks.push(datum);
		});
		if (update) this.paint();
	};
	
	//Draw points using a specified rendering class
	this.paint = function()
	{
		this.clear();

		//Ensure that classes are available
		this.addStyle('A');
		this.addStyle('T');
		this.addStyle('C');
		this.addStyle('G');
		this.addStyle('N');
		
		var width = this.getWidth();
		var height = this.getHeight();
		var brush = this.getBrush();
		var flippedX = this.isFlippedX();
		var flippedY = this.isFlippedY();
		var scaler = this.getScaler();
		
		Ext.each(stacks, function(stack)
		{
			var w = point.w;
			var x = flippedX ? width - point.x - w : point.x;

			brush.fillStyle = this.getStyle('A').fill;

			//FIXME: finish this off
			var h = Math.ceil(point.y * height * scaler);
			var y = flippedY ? 0 : height - h;

			if (x + w < 0 || x > width) return;

			brush.fillRect(x, y, w, h);
			
			//FIXME: the best way is to draw solid boxes for each letter group, then a collection of lines equal to the background color (white)
		});
	};
};
Ext.extend(StacksCanvas,PlotCanvas,{})
