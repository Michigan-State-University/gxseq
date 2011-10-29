var SixFrameList = function()
{
	SixFrameList.superclass.constructor.call(this);

	var self = this;
	var pe = false;
	
	//Parse information coming from the server into the list
	
	this.parse_lower = function(data)
	{
		if (!data) return;
		
		var sequence = [];
		for (var name in data)
		{
      if (!data[name]['frame']) continue;
      
      Ext.each(data[name]['frame'], function(datum)
			{
        if (datum.length != 6) return;
        if (datum[4] < 4 ) return;
				var sequence = {
					cls      : name,
					id       : datum[0] || '',
          x        : parseInt(datum[1]) || 0,
					w        : parseInt(datum[2]) || 0,
					sequence : datum[3] || '',
					frameNum   : parseInt(datum[4]) || 0,
					offset   : parseInt(datum[5]) || 0,
				};
				if (sequence.id && sequence.x >=0 && sequence.w >=0 && sequence.sequence)
				{	
					var node = self.createNode(sequence.id, sequence.x, sequence.x + sequence.w - 1, sequence);
					self.insert(node);
				}
			});
		}
	};
	
	this.parse_seq = function(data)
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
	
	this.parse_upper = function(data)
	{
		if (!data) return;
		
		var sequence = [];
		for (var name in data)
		{
      if (!data[name]['frame']) continue;
      
      Ext.each(data[name]['frame'], function(datum)
			{
        if (datum.length != 6) return;
        if (datum[4] > 3 ) return;
				var sequence = {
					cls      : name,
					id       : datum[0] || '',
          x        : parseInt(datum[1]) || 0,
					w        : parseInt(datum[2]) || 0,
					sequence : datum[3] || '',
					frameNum   : parseInt(datum[4]) || 0,
					offset   : parseInt(datum[5]) || 0,
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
  	this.subset2canvas_upper = function(x1, x2, bases, pixels)
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
  				x : Math.round((node.x1 - x1) * pixels / bases), //the distance in bases of this reads' LEFT edge from the left of the window
          w : Math.round((node.value.w) * pixels / bases) || 1,
          e : Math.round((node.value.readLen) * pixels / bases || 1),
          // e : Math.round((node.value.w) * pixels / bases) || 1,
  				cls : node.value.cls,
  				sequence : node.value.sequence,
					frameNum : node.value.frameNum,
					offset   : node.value.offset
  			});
  			return true;
  		});
  		return subset;
  	};
  
	
	//Returns a collection of points
	this.subset2canvas_seq = function(x1, x2, bases, pixels)
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
        // e : Math.round((node.value.w) * pixels / bases) || 1,
				cls : node.value.cls,
				sequence : node.value.sequence
			});
			return true;
		});
		return subset;
	};


	//Returns a collection of points
	this.subset2canvas_lower = function(x1, x2, bases, pixels)
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
				x : Math.round((node.x2 - x1) * pixels / bases),  //the distance in pixels of this reads' RIGHT edge from the left of the window
        w : Math.round((node.value.w) * pixels / bases) || 1,
        e : Math.round((node.value.readLen) * pixels / bases || 1),
        // e : Math.round((node.value.w) * pixels / bases) || 1,
				cls : node.value.cls,
				sequence : node.value.sequence,
				frameNum : node.value.frameNum,
				offset   : node.value.offset
			});
			return true;
		});  
		return subset;
	};
};
Ext.extend(SixFrameList,RangeList,{})
