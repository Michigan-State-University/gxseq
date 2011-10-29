var HistogramData = function()
{
	var series = new HistogramList();
	var max;
	var min;
	
	this.clear = function()
	{
		// for (var s in series)
		// {
		// 	series[s].clear();
		// }
		series.clear()
	};
	
	this.prune = function(x1,x2)
	{
		// for (var s in series)
		// {
		// 	series[s].prune(x1,x2);
		// }
		series.prune(x1,x2)
	};

	this.parse = function(data, above)
	{
		if (!data) return;
		// for (var name in data[2])
		// {
			// if (series[] == undefined)
			// {
				//series[above ? "above"] = new HistogramList();
			// }
			//series[above ? "below"].parse(data[2], above);
			series.parse(data);
		// }
	};
		
	this.subset2canvas = function(left, right, bases, pixels)
	{
		// var result = {};
		// 
		// for (var s in series)
		// {
		// 	result[s] = series[s].subset2canvas(left, right, bases, pixels);
		// }		
		// return result;
		return series.subset2canvas(left,right,bases,pixels);
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
			// if (datum.length == 3)
			// {
			// 	var item = {
			// 		x : parseInt(datum[0]),
			// 		w : 1,
			// 		y : parseFloat(datum[1] ) || 0
			// 	};
			// }
			// else
			// {
			// 	var item = {
			// 		x : parseInt(datum[0]),
			// 		w : parseInt(datum[1]) || 0,
			// 		y : parseFloat(datum[2]) || 0
			// 	};
			// }
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
			// if (active == null)
			// {
			// 	active = {
			// 		x : x,
			// 		y : y,
			// 		w : w
			// 	};
			// }
			// else if (x == active.x)
			// {
			// 	active.y = Math.max(active.y, y);
			// 	active.w = Math.max(active.w, w);
			// }
			// else
			// {
			// 	subset.push(active);
			// 	active = {
			// 		x : x,
			// 		y : y,
			// 		w : w
			// 	};
			// }
		});
		//if (active) subset.push(active);
		return subset;
	};
};
Ext.extend(HistogramList,PointList,{})
