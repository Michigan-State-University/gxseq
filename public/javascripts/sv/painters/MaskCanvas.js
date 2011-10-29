/*
 * Class for displaying gene models of other data with one level of nesting
 */
var MaskCanvas = function(userConfig)
{
	var self = this;
	var data = [];
	
	MaskCanvas.superclass.constructor.call(self, userConfig);

	var defaultConfig = {};
	
	Ext.apply(self.config, userConfig || {}, defaultConfig);
		
	this.setData = function(models)
	{
		if (!(models instanceof Array)) return;
		data = [];
		
		Ext.each(models, function(model)
		{
			model.x1 = model.x;
			model.x2 = model.x + model.w;
		});
		data = models;
	};
		
	//Draw points using a specified rendering class
	this.paint = function()
	{
		this.clear();
		if (!data || data.length == 0) return;
		
		var container = this.getContainer();
		var canvas = this.getCanvas();
		var region = this.getRegion();
		var width = this.getWidth();
		var height = this.getHeight();
		var brush = this.getBrush();
		var flippedX = this.isFlippedX();
		
		if (region == null) return;
		
		var y = 0;
		var h = height;
		
		Ext.each(data, function(model)
		{
			self.groups.add(model.cls);
			if (!self.groups.active(model.cls)) return;
			
			//Draw the model and its sub-components
			var w = model.w;
			var x = model.x;
			
			if (flippedX) x = width - x - w;
						
			if (x + w < region.x1 || x > region.x2) return;
	
			self.paintBox(model.cls, x, y, w, h);						
		});
	};	
};
Ext.extend(MaskCanvas,BoxesCanvas,{})