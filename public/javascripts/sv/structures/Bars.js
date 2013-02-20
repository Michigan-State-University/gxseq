var HistogramData = function()
{
	var series = new HistogramList();
	var max;
	var min;// TODO: where are these used
	
	this.clear = function()
	{
		series.clear()
	};
	
	this.prune = function(x1,x2)
	{
		series.prune(x1,x2)
	};

	this.parse = function(data, above)
	{
		if (!data) return;
		series.parse(data);
	};
		
	this.subset2canvas = function(left, right, bases, pixels)
	{
		return series.subset2canvas(left,right,bases,pixels);
	};
	
	this.getMaxY = function(x1, x2)
	{
    return series.getMax(x1,x2);
	};
};	

var HistogramList = function()
{
	HistogramList.superclass.constructor.call(this);

	var self = this;
	
	//Parse information coming from the server into the list
	this.parse = function(data)
	{
		var points = [];
		Ext.each(data, function(datum)
		{
			if (!datum) return;
			var item ={
				x : parseInt(datum[0]),
				y : parseFloat(datum[1]),
				w : 1
			}
			item.id = item.x;
			if (!item.w || !item.y) return;
			
			points.push(self.createNode(item.id, item.x, item));
		});
		self.insertPoints(points);
	};
		
	//Get a subset to use for a histogram canvas
	this.subset2canvas = function(x1,x2,bases,pixels)
	{
		var active = null;
		var subset = [];
		var bases = parseInt(bases) || 0;
		var pixels = parseInt(pixels) || 0;
		
		if (!bases || !pixels) return subset;

		self.viewport.update(x1,x2);
		self.viewport.apply(function(item)
		{
			
			var x = Math.round((item.x - x1) * pixels / bases);
			var y = item.y;
			var w = Math.round(item.w * pixels / bases) || 1;
			subset.push(
				{
					x : x,
					y : y,
					w : w
				})
		});
		return subset;
	};
	
	//Return the maximum y-value from the list
	this.getMax =function(x1,x2){
	  var max = 0;
	  //prune the viewport to left and right
	  self.viewport.update(x1,x2);
		self.viewport.apply(function(item)
		{
		  if(item.y>max){max=item.y;}
	  });
	  return max;
	};
};
Ext.extend(HistogramList,PointList,{})
