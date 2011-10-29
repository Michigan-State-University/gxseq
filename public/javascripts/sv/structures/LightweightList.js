var LightweightList = function()
{	
	var self = this;
	
	var first = null;
	var last  = null;
	var count = 0;
	
	var Node = function(item)
	{
		this.next = null;
		this.prev = null;
		this.value = item;
	};
	
	this.getFirst = function() { return first; };
	this.getLast  = function() { return last;  };
	this.getCount = function() { return count; };
	
	this.prepend = function(item)
	{
		var node = new Node(item);
		
		if (!first)
		{
			first = node;
			last = node;
		}
		else
		{
			node.next = first;
			node.prev = null;
			node.next.prev = node;
			first = node;
		}
		count++;
	};
	
	this.append = function(item)
	{
		var node = new Node(item);
		
		if (!last)
		{
			first = node;
			last = node;
		}
		else
		{
			node.next = null;
			node.prev = last;
			node.prev.next = node;
			last = node;
		}
		count++;
	};
	
	this.insertAfter = function(existing, item)
	{
		if (!(existing instanceof Node))
		{
			return;
		}
		if (existing == last)
		{
			self.append(item);
			return;	
		}		
		var node = new Node(item);		
		node.next = existing.next;
		node.prev = existing;
		node.next.prev = node;
		node.prev.next = node;
		count++;
	};
	
	this.insertBefore = function(existing, item)
	{
		if (!(existing instanceof Node))
		{
			return;
		}
		if (existing == first)
		{
			self.prepend(item);
			return;	
		}		
		var node = new Node(item);		
		node.next = existing;
		node.prev = existing.prev;
		node.next.prev = node;
		node.prev.next = node;
		count++;
	};
		
	this.remove = function(existing)
	{
		if (!(existing instanceof Node) || count == 0)
		{
			return;
		}
		if (count == 1)
		{
			first = null;
			last = null;
		}
		else
		{
			if (existing == first)
			{
				first = existing.next;
				first.prev = null;
			}
			else if (existing == last)
			{
				last = existing.prev;
				last.next = null;
			}
			else
			{
				existing.prev.next = existing.next;
				existing.next.prev = existing.prev;
			}
		}
		existing.next = null;
		existing.prev = null;
		delete existing;
		count--;
	};
	
	this.clear = function()
	{
		while (first)
		{
			remove(first);
		}
		count = 0;
	};
	
	this.each = function(func)
	{
		if (!func || !(func instanceof Function))
		{
			return;
		}
		for (var node=first; node; node=node.next)
		{
			if (!func(node.value))
			{
				break;
			}
		}
	};
	
	this.find = function(value)
	{
		for (var node=first; node; node=node.next)
		{
			if (node.value == value)
			{
				return node;
			}
		}
		return null;
	};	
};