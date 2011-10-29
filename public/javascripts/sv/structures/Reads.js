var ReadsList = function()
{
	ReadsList.superclass.constructor.call(this);

	var self = this;
	var pe = false;
	
	//Parse information coming from the server into the list
	this.parse = function(data, above, pe, peLength)
	{
		if (!data) return;
		if (!pe) pe = false;
		if (!peLength) peLength = 36;

		var reads = [];
		
		for (var name in data)
		{
			if (!data[name]['watson'] || !data[name]['crick']) continue;
			
			Ext.each(data[name][above ? 'watson' : 'crick'], function(datum)
			{ 
				if (datum.length != 6) return;
				
				var read = {
					cls      : name,
					strand   : above ? '+' : '-',
					id       : datum[0] || '',
					x        : parseInt(datum[1]) || 0,
					w        : parseInt(datum[2]) || 0,
					places   : parseInt(datum[3]) || 0,
					copies   : parseInt(datum[4]) || 0,
					readLen  : peLength,
					sequence : datum[5] || ''
				};
				if (read.id && read.x && read.w && read.places && read.copies)
				{
					if (read.places > 1) read.cls += ' multi_mapper';
					if (read.copies > 1) read.cls += ' multi_copies';
					
					var node = self.createNode(read.id, read.x, read.x + read.w - 1, read);
					self.insert(node);
					//reads.push(node);
				}
			});
		}
		//self.insertArray(reads);
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
				e : Math.round((node.value.readLen) * pixels / bases || 1),
				cls : node.value.cls,
				sequence : node.value.sequence
			});
			return true;
		});
		return subset;
	};
};
Ext.extend(ReadsList,RangeList,{})
