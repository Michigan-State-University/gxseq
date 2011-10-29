var RangeList = function()
{
	var index  = {};
	var count  = 0;
	var self   = this;
	var firstNode = null;
	var lastNode  = null;
	var viewL  = null;
	var viewR  = null;
	
	var RangeNode = function(id,x1,x2,item)
	{
		this.id = id || '';
		this.x1 = parseInt(x1) || 0;
		this.x2 = parseInt(x2) || 0;
		this.value = item || null;
		this.level = -1;
		
		this.next = null;
		this.prev = null;
	};
	
	//Getters
	this.getCount  = function() { return count;  };
	this.getFirstL = function() { return firstNode; };
	this.getLastL  = function() { return lastNode;  };
	this.getIndex  = function() { return index;  };
	
	//Create a new range node
	this.createNode = function(id, x1, x2, item)
	{
		return new RangeNode(id, x1, x2, item);
	};
	
	//Check if an item is already in the list
	this.exists = function(id)
	{
		if (!id) return false;
		return index[id] ? true : false;
	};
	
	//Get a node by its ID
	this.getNode = function(id)
	{
		if (!id) return null;
		return index[id] || null;
	};
	
	//Get the value of a node by its ID
	this.getValue = function(id)
	{
		if (!id) return null;
		if (!index[id]) return null;
		return index[id].value;
	};
		
	//Clear out the list entirely
	 this.clear = function()
	 {
		while (firstNode)
		{
			self.remove(firstNode);
		}
	 };	

	//Delete nodes that lie outside the specified range
	this.prune = function(x1, x2)
	{
		while (firstNode && firstNode.x2 < x1)
		{
			self.remove(firstNode);
		}
		while (lastNode && lastNode.x1 > x2)
		{
			self.remove(lastNode);
		}
	};	

	//Parse incoming data into the list (provide functionality with subclasses)
	this.parse = function(data)
	{
	};
		
	//Apply a function to all items in the list
	this.apply = function(func)
	{
		if (!(func instanceof Function)) return;
				
		for (var node=firstNode; node; node=node.next)
		{
			func(node);
		}
	};	
	
	//Add a new item
	this.insert = function(node)
	{
		if (!(node instanceof RangeNode)) return;
    
		if (index[node.id])
		{
			//index[node.id].value = node.value;
			return;
		}
		index[node.id] = node;
						
		//Special case when the list is empty
		if (count == 0)
		{
			firstNode = node;
			lastNode = node;
			count = 1;
			return;
		}
			
		//Link the left edges
		if (node.x1 < firstNode.x1 || (node.x1 == firstNode.x1 && node.x2 >= firstNode.x2))
		{
			node.next = firstNode;
			firstNode.prev = node;
			firstNode = node;
		}
		else if (node.x1 > lastNode.x1 || (node.x1 == lastNode.x1 && node.x2 <= lastNode.x2))
		{
			node.next = null;
			node.prev = lastNode;
			node.prev.next = node;
			lastNode = node;
		}
		else
		{
			//Between first and last -> link from the closest side
			if (Math.abs(node.x1 - firstNode.x1) < Math.abs(node.x1 - lastNode.x1))
			{
				for (var existing=firstNode; existing; existing=existing.next)
				{
					if (node.x1 < existing.x1 || (node.x1 == existing.x1 && node.x2 >= existing.x2))
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
				for (var existing=lastNode; existing; existing=existing.prev)
				{
					if (node.x1 > existing.x1 || (node.x1 == existing.x1 && node.x2 <= existing.x2))
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
	
	//Remove an existing node
	this.remove = function(node)
	{
		if (!(node instanceof RangeNode)) return;
		if (!index[node.id]) return;
		if (count == 0) return;
		
		if (node == viewL) viewL = node.next;
		if (node == viewR) viewR = node.prev;
		
		//A shortcut can be taken if there is only one node in the list
		if (count == 1)
		{
			firstNode = null;
			//firstR = null;
			lastNode = null;
			//lastR = null;		
		}
		else
		{
			//L side unlinking
			if (node == firstNode)
			{
				firstNode = node.next;
				firstNode.prev = null;
			}
			else if (node == lastNode)
			{
				lastNode = node.prev;
				lastNode.next = null;
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
	
	//Levelize all items. Checking function can be used to select which items will be included
	this.levelize = function(func)
	{
		var max = 0;
		var added = false;
		var inplay = new lightweight_list();
		
		//Levelize all items
		for (var rangeNode=firstNode; rangeNode; rangeNode=rangeNode.next)
		{
			if (func && !func(rangeNode.value)) continue;
			
			added = false;
			rangeNode.level = 0;

			//Remove out of play rangeNodes
			for (var node=inplay.first; node; node=node.next)
			{
				if (node.value.x2 <= rangeNode.x1)
				{
					inplay.remove(node);
				}
			}
			
			//Assign the rangeNode a level
			for (var node=inplay.first; node; node=node.next)
			{
				if (rangeNode.level < node.value.level)
				{
					inplay.insertAfter(node.prev, rangeNode);
					added = true;
					break;
				}
				rangeNode.level++;
				max = Math.max(max, rangeNode.level);
			}
			
			//If no place was found to add the rangeNode, then append it
			if (!added) inplay.insertLast(rangeNode);
		};
		return max;
	};
	
	//Viewport represents a window into the data structure
	this.viewport = (function()
	{
		//Get the current nodes of the viewport
		function get()
		{
			return {
				viewL : viewL,
				viewR : viewR
			};
		};
		
		//Forcefully set the position of the viewport
		function set(x1, x2)
		{
			var x1 = parseInt(x1) || 0;
			var x2 = parseInt(x2) || 0;
	
			if (x1 > x2) return;
			
			viewL = null;
			viewR = null;
			
			//Traverse Nodes in order. Use Left(x1) sorted list.
			//Find leftmost node
			for(var node=firstNode; node; node=node.next)
			{
				if (node.x2 < x1) continue;
				viewL = node;
				viewR = node;
				if (node.x1 > x1) break;				
			}
			//Find rightmost node
			for(var node=viewL; node; node=node.next)
			{
				if (node.x1 > x2){
					viewR = node.prev;
					break;
				}
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
			while (viewL && viewL.x2 < x1)
			{
				viewL = viewL.next;
			}
			while (viewR && viewR.x1 > x2)
			{
				viewR = viewR.prev;
			}
			
			//Extend the edges
			while (viewL && viewL.prev && viewL.prev.x2 >= x1)
			{
				viewL = viewL.prev;
			}
			while (viewR && viewR.next && viewR.next.x1 <= x2)
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
		
		//Apply a function to all elements within the viewport
		function apply(func)
		{
			if (!(func instanceof Function)) return false;
			
			if (!viewL || !viewR) return;
			
			for (var node=viewL; node; node=node.next) //changed from nextR
			{
				func(node);
        // console.log("applying func to : "+node.value.x)
				if (node == viewR) break;
			}
			return true;
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
