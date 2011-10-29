var PointList = function()
{
	var index = {};
	var count = 0;
	var self  = this;
	var first = null;
	var last  = null;
	var viewL = null;
	var viewR = null;
	var hash = {};
	
	var PointNode = function(id,x,item)
	{
		this.id = id || '';
		this.x = parseInt(x) || 0;
		this.value = item || null;
		
		this.next = null;
		this.prev = null;
	};	
	
	//Getters
	this.getCount = function() { return count; };
	this.getFirst = function() { return first; };
	this.getLast  = function() { return last;  };
	this.getIndex = function() { return index; };
		
	//Create a new point node
	this.createNode = function(id, x, item)
	{
		return new PointNode(id, x, item);
	};
			
	//Clear out the list entirely
	this.clear = function()
	{
		while (first)
		{
			self.remove(first);
		}
	};	

	//Delete nodes that lie outside the specified range
	this.prune = function(x1, x2)
	{
		while (first && first.x < x1)
		{
			self.remove(first);
		}
		while (last && last.x > x2)
		{
			self.remove(last);
		}
	};	

	//Parse incoming data into the list (provide functionality with subclasses)
	this.parse = function(data)
	{
	};
	
	//Returns a subset of all items that intersect the specified range (as an array)
	this.subset = function(x1, x2)
	{
		var data = [];
		
		var x1 = parseInt(x1) || 0;
		var x2 = parseInt(x2) || 0;
		
		if (x1 > x2) return data;

		for (var node=first; node; node=node.next)
		{
			if (node.x < x1) continue;
			if (node.x > x2) break;			
			data.push(node.value);
		}
		return data;
	};
	
	//Apply a function to all items in the specified range (all nodes if no range given)
	this.apply = function(func, x1, x2)
	{
		if (!(func instanceof Function)) return;
		
		var x1 = parseInt(x1) || first.x;
		var x2 = parseInt(x2) || last.x;

		if (x1 > x2) return;
		
		for (var node=first; node; node=node.next)
		{
			if (node.x < x1) continue;
			
			while (node)
			{
				if (node.x > x2) break;
				func(node);
				node = node.next;
			}
			break;
		}
	};
	
	//Add a new item
	this.insert = function(node)
	{
		if (!(node instanceof PointNode)) return;

		if (index[node.id])
		{
			index[node.id].value = node.value;
			return;
		}
		index[node.id] = node;
						
		//Special case when the list is empty
		if (count == 0)
		{
			first = node;
			last = node;
			count = 1;
			return;
		}
		
		//Link the node
		if (node.x <= first.x)
		{
			node.next = first;
			first.prev = node;
			first = node;
		}
		else if (node.x >= last.x)
		{
			node.next = null;
			node.prev = last;
			node.prev.next = node;
			last = node;
		}
		else
		{
			//Add from the end if closer to the end
			if (Math.abs(node.x - first.x) < Math.abs(node.x - last.x))
			{
				for (var existing=first; existing; existing=existing.next)
				{
					if (node.x <= existing.x)
					{
						node.next = existing;
						node.prev = existing.prev;
						node.next.prev = node;
						node.prev.next = node;
						break;
					}
				}
			}
			else
			{
				for (var existing=last; existing; existing=existing.prev)
				{
					if (node.x >= existing.x)
					{
						node.next = existing.next;
						node.prev = existing;
						node.next.prev = node;
						node.prev.next = node;
						break;
					}
				}
			}
		}
		count++;
	};
	
	//Insert an array of points
	this.insertPoints = function(array)
	{
		var len = array.length;
		if (len == 0) return;
				
		//Add from the start if closest to there
		if (count > 0 && Math.abs(array[0].x - first.x) < Math.abs(array[0].x - last.x))
		{
			for (var i=len-1; i>=0; i--)
			{
				self.insert(array[i]);
			}
		}
		else
		{
			for (var i=0; i<len; i++)
			{
				self.insert(array[i]);
			}
		}
	};
		
	//Remove an existing node
	this.remove = function(node)
	{
		if (!(node instanceof PointNode)) return;
		if (!index[node.id]) return;
		if (count == 0) return;
				
		//A shortcut can be taken if there is only one node in the list
		if (count == 1)
		{
			first = null;
			last = null;
			viewL = null;
			viewR = null;
		}
		else
		{
			if (node == viewL)
			{
				viewL = node.next;
			}
			if (node == viewR)
			{
				viewR = node.prev;
			}
			if (node == first)
			{
				first = node.next;
				first.prev = null;
			}
			else if (node == last)
			{
				last = node.prev;
				last.next = null;
			}
			else
			{
				node.prev.next = node.next;
				node.next.prev = node.prev;
			}
		}
		node.prev = null;
		node.next = null;			
		delete index[node.id];
		delete node;
		count--;
	};
	
	//Viewport represents a window into the data structure
	this.viewport = (function()
	{
		//Get the current nodes of the viewport
		function get()
		{
			return {
				left : viewL,
				right : viewR
			};
		};
		
		//Forcefully set the position of the viewport
		function set(x1, x2)
		{
			if (count == 0)
			{
				clear();
				return;
			}

			var x1 = parseInt(x1) || 0;
			var x2 = parseInt(x2) || 0;
	
			if (x1 > x2) return;
	
			for (var node=first; node; node=node.next)
			{
				if (node.x < x1) continue;
				viewL = node;
				
				while (node)
				{
					if (node.x > x2) break;
					viewR = node;
					node = node.next;
				}
				break;
			}
		};
		
		//Update the edges of the window
		function update(x1, x2)
		{
			var x1 = parseInt(x1) || 0;
			var x2 = parseInt(x2) || 0;
	
			if (x1 > x2) return;

			if (!viewL || !viewR)
			{
				set(x1, x2);
				return;
			}
			
			//Prune the edges
			while (viewL && viewL.x < x1)
			{
				viewL = viewL.next;
			}
			while (viewR && viewR.x > x2)
			{
				viewR = viewR.prev;
			}		
			
			//Extend the edges
			while (viewL && viewL.prev && viewL.prev.x >= x1)
			{
				viewL = viewL.prev;
			}
			while (viewR && viewR.next && viewR.next.x <= x2)
			{
				viewR = viewR.next;
			}		
		};
		
		//Clear the window
		function clear()
		{
			viewL = null;
			viewR = null;
		};
		
		//Apply a function too all elements within the viewport
		function apply(func)
		{
			if (!(func instanceof Function)) return;
					
			for (var node=viewL; node; node=node.next)
			{
				func(node.value);
				if (node == viewR) break;
			}		
		};
				
		return {
			get : get,
			set : set,
			clear : clear,
			update : update,
			apply : apply
		};
	})();
};
