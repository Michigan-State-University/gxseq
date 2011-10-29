var PairedReadsList = function()
{
	PairedReadsList.superclass.constructor.call(this);

	var self = this;
	
	//Parse information coming from the server into the list
	this.parse = function(data, above)
	{
		if (!data) return;

		var reads = [];
		
		for (var name in data)
		{
			if (!data[name]['watson'] || !data[name]['crick']) continue;
			
			Ext.each(data[name][above ? 'watson' : 'crick'], function(datum)
			{
				if (datum.length != 7) return;
				
				var read = {
					cls    : name,
					strand : above ? '+' : '-',
					id     : datum[0] || '',
					x      : parseInt(datum[1]) || 0,
					w      : parseInt(datum[2]) || 0,
					lenA   : parseInt(datum[3]) || 0,
					lenB   : parseInt(datum[4]) || 0,
					seqA   : datum[5],
					seqB   : datum[6]
				};
				
				if (read.id && read.x && read.w)
				{
					var node = self.createNode(read.id, read.x, read.x + read.w - 1, read);
					self.insert(node);
				}
			});
		}
	};
	
	//Returns a collection of points for use with a histogram canvas
	this.subset2canvas = function(x1, x2, bases, pixels)
	{
		var subset = [];
		var bases = parseInt(bases) || 0;
		var pixels = parseInt(pixels) || 0;
		
		if (!bases || !pixels) return subset;

		self.viewport.update(x1,x2);
		self.viewport.apply(function(node)
		{
			if (node.x2 < x1) return true;
			
			subset.push(
			{
				x : Math.round((node.x1 - x1) * pixels / bases),
				w : Math.round((node.value.w) * pixels / bases) || 1,
				e1 : Math.round((node.value.lenA) * pixels / bases),
				e2 : Math.round((node.value.lenB) * pixels / bases),
				cls : node.value.cls,
				seqA : node.value.seqA,
				seqB : node.value.seqB
			});
			return true;
		});
		return subset;
	};
};
Ext.extend(PairedReadsList,RangeList,{})
