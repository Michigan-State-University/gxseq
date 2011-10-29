var SequenceList = function()
{
	SequenceList.superclass.constructor.call(this);

	var self = this;
	var pe = false;
	
	//get the first sequence data in bases
	this.get = function(start, length)
	{
		data=""
		node = self.viewport.get().viewL
		idx = start - node.x1
		for(i=0;i<length;i++){
			data+=node.value.sequence.charAt(idx+i)
		}
		return data;
	};
	//Parse information coming from the server into the list
	this.parse = function(data)
	{
		if (!data) return;
		
		var sequence = [];
		for (var name in data)
		{
      if (!data[name]['seq']) continue;
      
      Ext.each(data[name]['seq'], function(datum)
			{
        if (datum.length != 4) return;
				
				var sequence = {
					cls      : name,
					id       : datum[0] || '',
          x        : parseInt(datum[1]) || 0,
					w        : parseInt(datum[2]) || 0,
					sequence : datum[3] || ''
				};
				if (sequence.id && sequence.x >=0 && sequence.w >=0 && sequence.sequence)
				{	
					var node = self.createNode(sequence.id, sequence.x, sequence.x + sequence.w - 1, sequence);
					self.insert(node);
				}
			});
		}
	};
	
	//Returns a collection of points
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
Ext.extend(SequenceList,RangeList,{})
