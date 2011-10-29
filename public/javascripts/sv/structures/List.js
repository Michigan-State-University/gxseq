var List = function()
{
	var index = {};
	var count = 0;
	var self  = this;
	var first = null;
	var last  = null;
	
	var Node = function(id, value)
	{
		this.id = id || 0;
		this.next = null;
		this.prev = null;
		this.value = value;
	};
	
	//Getters
	this.getCount = function() { return count; };
	this.getFirst = function() { return first; };
	this.getLast  = function() { return last;  };
	this.getIndex = function() { return index; };
	
	//Check if an item is already in the list
	this.exists = function(id)
	{
		return index[id] ? true : false;
	};
	
	//Get the value from a certain position
	this.get = function(id)
	{
		return index[id].value || null;
	};
	
	//Extract a subset of this range list (as an array)
	this.subset = function(id1, id2)
	{
		var items = [];

		if (count == 0) return items;

		if (id1 == undefined) id1 = first.id;
		if (id2 == undefined) id2 = last.id;

		if (id1 > id2) return items;
				
		for (var node=first; node; node=node.next)
		{
			if (node.id < id1) continue;
			if (node.id > id2) break;			
			items.push(node.value);
		}
		return items;
	};
	
	//Delete nodes that lie outside the specified range
	this.prune = function(id1, id2)
	{
		while (first && first.id < id1)
		{
			self.remove(first);
		}
		while (last && last.id > id2)
		{
			self.remove(last);
		}
	};
	
	//Clear out the list entirely
	this.clear = function()
	{
		while (first)
		{
			self.remove(first);
		}
	};	
	
	//Add a new item
	this.insert = function(id, item)
	{
		if (id == undefined || item == undefined) return;
		
		var node = new Node(id, item);

		index[id] = node;
						
		//Special case when the list is empty
		if (count == 0)
		{
			first = node;
			last  = node;
			count = 1;
			return;
		}
		
		//Slot the node into the linked list. Shortcuts for head and tail, otherwise work backwards and insert after insert point.
		if (node.id < first.id)
		{
			node.prev = null;
			node.next = first;
			node.next.prev = node;
			first = node;
		}
		else if (node.id >= last.id)
		{
			node.next = null;
			node.prev = last;
			node.prev.next = node;
			last = node;
		}
		else
		{
			for (var existing=last; existing; existing=existing.prev)
			{
				if (node.id >= existing.id)
				{
					node.next = existing.next;
					node.prev = existing;
					node.next.prev = node;
					node.prev.next = node;
				}
			}
		}
		count++;
	};
	
	//Remove an existing node. If a function is provided then it is applied to the value of the deleted node before deletion
	this.remove = function(node)
	{
		if (!node instanceof Node) return;
		if (!index[node.id]) return;
		if (count == 0) return;
		
		//A shortcut can be taken if there is only one node in the list
		if (count == 1)
		{
			first = null;
			last  = null;
		}
		else
		{
			if (node == first)
			{
				first = node.next;
				first.prev = null;
				node.next = null;
			}
			else if (node == last)
			{
				last = node.prev;
				last.next = null;
				node.prev = null;
			}
			else
			{
				node.next.prev = node.prev;
				node.prev.next = node.next;
				node.prev = null;
				node.next = null;
			}
		}
		delete index[node.id];
		delete node;
		count--;
	};
};
