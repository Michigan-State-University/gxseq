AnnoJ.Helpers.List = function()
{	
	var self = this;
	
	this.first = null;
	this.last  = null;
	this.count = 0;
	
	var Node = function(item)
	{
		this.next = null;
		this.prev = null;
		this.value = item;
	};
	
	this.insertFirst = function(item)
	{
		var node = new Node(item);
		
		if (!self.first)
		{
			self.first = node;
			self.last = node;
		}
		else
		{
			node.next = self.first;
			node.prev = null;
			node.next.prev = node;
			self.first = node;
		}
		self.count++;
	};
	
	this.insertLast = function(item)
	{
		var node = new Node(item);
		
		if (!self.last)
		{
			self.first = node;
			self.last = node;
		}
		else
		{
			node.next = null;
			node.prev = self.last;
			node.prev.next = node;
			self.last = node;
		}
		self.count++;
	};
	
	this.insertBefore = function(existing, item)
	{
		if (existing == null)
		{
			self.insertLast(item);
			return;	
		}		
		if (!existing instanceof Node)
		{
			return;
		}
		if (existing == self.first)
		{
			self.insertFirst(item);
			return;
		}
		var node = new Node(item);		
		node.next = existing;
		node.prev = existing.prev;
		node.next.prev = node;
		node.prev.next = node;
		self.count++;
	};
	
	this.insertAfter = function(existing, item)
	{
		if (existing == null)
		{
			self.insertFirst(item);
			return;	
		}
		if (!existing instanceof Node)
		{
			return;
		}
		if (existing == self.last)
		{
			self.insertLast(item);
			return;
		}
		var node = new Node(item);
		node.prev = existing;
		node.next = existing.next;
		node.next.prev = node;
		node.prev.next = node;
		self.count++;
	};
		
	this.remove = function(existing)
	{
		if (!existing instanceof Node)
		{
			return;
		}
		if (existing == self.first && existing == self.last)
		{
			self.first = null;
			self.last = null;
		}
		else if (existing == self.first)
		{
			self.first = existing.next;
			self.first.prev = null;
		}
		else if (existing == self.last)
		{
			self.last = existing.prev;
			self.last.next = null;
		}
		else
		{
			existing.next.prev = existing.prev;
			existing.prev.next = existing.next;
		}
		existing.prev = null;
		existing.next = null;
		temp = existing.value;
		delete existing;
		self.count--;
		return temp;
	};
	
	this.clear = function()
	{
		var vals = [];
		while (self.first)
		{
			vals.push(remove(self.first));
		}
		self.count = 0;
		return vals;
	};
	
	//Apply a function to all elements of the list
	this.apply = function(func)
	{
		if (func == undefined || !(func instanceof Function))
		{
			return;
		}
		for (var node=self.first; node; node=node.next)
		{
			if (!func(node.value))
			{
				break;
			}
		}
	};
	
	//Find a particular node in the list by the value it contains
	this.find = function(value)
	{
		for (var node=self.first; node; node=node.next)
		{
			if (node.value == value)
			{
				return node;
			}
		}
		return null;
	};	
};