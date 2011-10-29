//Global mouse listener (only tracks left button)
var Mouse = function()
{
	var self = this;
	
	this.addEvents({
		'dragStarted'   : true,
		'dragged'       : true,
		'dragEnded'     : true,
		'dragCancelled' : true,
		'pressed'       : true,
		'released'      : true,
		'moved'         : true
	});

	var mouse = {
		x : 0,
		y : 0,
		down : false,
		drag : false,
		downX : 0,
		downY : 0,
		target : null
	};
	

	Ext.EventManager.addListener(window, 'mousedown', function(event)
	{   
		if (event.button != 0) return;
		if (event.getTarget().tagName == 'INPUT') return;
		
		mouse.x = event.getPageX();
		mouse.y = event.getPageY();
		mouse.drag = false;
		mouse.down = true;
		mouse.downX = mouse.x;
		mouse.downY = mouse.y;
		mouse.target = event.getTarget();
		self.fireEvent('pressed', mouse);
	});	
	Ext.EventManager.addListener(window, 'mousemove', function(event)
	{
		mouse.x = event.getPageX();
		mouse.y = event.getPageY();
		mouse.target = event.getTarget();
		
		if (!mouse.down)
		{
			self.fireEvent('moved', mouse);
			return;
		}
		
		if (!mouse.drag)
		{
			mouse.drag = true;
			self.fireEvent('dragStarted', mouse);
		}
		else
		{
			self.fireEvent('dragged', mouse);
		}
	});
	Ext.EventManager.addListener(window, 'mouseup', function(event)
	{
		if (event.button != 0) return;
		if (!mouse.down) return;

		mouse.x = event.getPageX();
		mouse.y = event.getPageY();
		mouse.target = event.getTarget();
		
		mouse.down = false;

		if (mouse.drag)
		{
			mouse.drag = false;
			self.fireEvent('dragEnded', mouse);
		}
		else
		{
			self.fireEvent('released', mouse);
		}
	});
	Ext.EventManager.addListener(window, 'keydown', function()
	{
		if (mouse.drag)
		{
			mouse.drag = false;
			self.fireEvent('dragCancelled', mouse);
		}
	});
	
	this.getMouse = function()
	{
		return mouse;
	};
};
// Ext.extend(Mouse, Ext.util.Observable);
Ext.extend(Mouse,Ext.util.Observable,{})
var Mouse = new Mouse();
