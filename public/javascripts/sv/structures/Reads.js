var ReadsList = function()
{
	ReadsList.superclass.constructor.call(this);

	var self = this;
	var pe = false;
	
	//Parse information coming from the server into the list
	this.parse = function(data)
	{
	  try{
	  
  		if (!data) return;
  		var msg = null;
  		for (var name in data)
  		{
  		  if(name=='notice'){
  		    msg = data[name];
  		  }
  		  else{			
    			Ext.each(data[name], function(datum)
    			{ 
    				if (datum.length < 5) return msg;
				
    				var read = {
    					cls      : name,
    					id       : datum[0] || '',
    					x        : parseInt(datum[1]) || 0,
    					w        : parseInt(datum[2]) || 0,
    					strand   : datum[3],
    					sequence : datum[4] || '',
    					children : datum[5]
    				};
    				if (read.id && read.x && read.w )
    				{
					    //composite: id plus position because Bam ID's are not unique 
    					var node = self.createNode(read.id+read.x, read.x, read.x + read.w - 1, read);
    					self.insert(node);
    				}
    			});
    		}
  		}
  		//self.insertArray(reads);
  		return msg;
		}catch (err)
		{
		  return "Error Parsing Data";
		};
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
				//e : Math.round((node.value.readLen) * pixels / bases || 1),
				cls : node.value.cls,
				sequence : node.value.sequence,
				level : node.level,
				strand : node.value.strand,
				id : node.id,
				children : node.value.children
			});
			return true;
		});
		return subset;
	};
};
Ext.extend(ReadsList,RangeList,{})
