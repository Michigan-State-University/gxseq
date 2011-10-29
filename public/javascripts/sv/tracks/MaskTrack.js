/*
 * Simple mask track for representing linear box series without levelizing collisions
 */
AnnoJ.MaskTrack = function(userConfig)
{	
	AnnoJ.MaskTrack.superclass.constructor.call(this, userConfig);

	var self = this;

	var defaultConfig = {
		single    : false,
		clsAbove  : 'AJ_above',
		clsBelow  : 'AJ_below'
	};
	Ext.apply(self.config, userConfig || {}, defaultConfig);

	//Initialization
	var containerA = new Ext.Element(document.createElement('DIV'));
	var containerB = new Ext.Element(document.createElement('DIV'));
	
	containerA.addCls(self.config.clsAbove);
	containerB.addCls(self.config.clsBelow);
	
	//Force some styles
	containerA.setStyle('position', 'relative');
	containerB.setStyle('position', 'relative');
	containerA.setStyle('width', '100%');
	containerB.setStyle('width', '100%');

	if (self.config.single)
	{
		containerA.setStyle('height', '100%');
		containerB.setStyle('display', 'none');
	}
	else
	{
		containerA.setStyle('height', '49%');
		containerB.setStyle('height', '49%');
		containerA.setStyle('borderBottom', 'dotted black 1px');
	}
	
	containerA.appendTo(self.Canvas.ext);
	containerB.appendTo(self.Canvas.ext);
	
	//Data handler and renderer
	var Models = (function()
	{
		var dataA = new ModelsList();
		var dataB = new ModelsList();
	
		function parse(data)
		{
			dataA.parse(data,true);
			dataB.parse(data,false);			
		};

		var canvasA = new MaskCanvas();
		var canvasB = new MaskCanvas();

		canvasA.setContainer(containerA.dom);
		canvasB.setContainer(containerB.dom);
		
		function paint(left, right, bases, pixels)
		{
			var subsetA = dataA.subset2canvas(left, right, bases, pixels);
			var subsetB = dataB.subset2canvas(left, right, bases, pixels);

			canvasA.setData(subsetA);
			canvasB.setData(subsetB);
			
			canvasA.paint();
			canvasB.paint();
			
			var list = canvasA.groups.getList();
			
			for (var series in list)
			{
				addLabel(series);
			}
			
			list = canvasB.groups.getList();
			
			for (var series in list)
			{
				addLabel(series);
			}
		};
		
		return {
			dataA : dataA,
			dataB : dataB,
			canvasA : canvasA,
			canvasB : canvasB,
			parse : parse,
			paint : paint
		};		
	})();
	
	//Data handling and rendering object
	var handler = Models;	
		
	//Zoom policies (dictate which handler to use)
	var policies = [
		{ index:0, min:1/100 , max:10/1   , bases:1   , pixels:1  , cache:10000   },
		{ index:1, min:10/1  , max:100/1  , bases:10  , pixels:1  , cache:100000  },
		{ index:2, min:100/1 , max:1000/1 , bases:100 , pixels:1  , cache:1000000 }
	];
	
	//Data series labels
	var labels = null;
		
	//Add series name to context menu (checkbox controls series visibility)
	function addLabel(name)
	{
		if (!labels)
		{
			self.ContextMenu.addItems(['-','Series']);
			labels = {};
		}

		if (labels[name] == undefined)
		{
			labels[name] = true;
		
			self.ContextMenu.addItems([
				new Ext.menu.CheckItem(
				{
					text    : name,
					checked : true,
					handler : function()
					{
						handler.canvasA.groups.toggle(name, !this.checked);
						handler.canvasB.groups.toggle(name, !this.checked);
						handler.canvasA.refresh();
						handler.canvasB.refresh();
					}
				})
			]);
		}
	};
		
	this.getPolicy = function(view)
	{
		var ratio = view.bases / view.pixels;
		
		for (var i=0; i<policies.length; i++)
		{
			if (ratio >= policies[i].min && ratio < policies[i].max)
			{			
				return policies[i];
			}
		}
		return null;
	};

	//Track overrides
	this.rescale = function() {};

	this.clearCanvas = function()
	{
		handler.canvasA.clear();
		handler.canvasB.clear();
	};
	this.paintCanvas = function(l,r,b,p)
	{
		handler.paint(l,r,b,p);
	};
	this.refreshCanvas = function()
	{
		handler.canvasA.refresh();
		handler.canvasB.refresh();
	};
	this.resizeCanvas = function()
	{
		handler.canvasA.refresh();
		handler.canvasB.refresh();
	};
	this.clearData = function()
	{
		handler.dataA.clear();
		handler.dataB.clear();
	};
	this.pruneData = function(a,b)
	{
		handler.dataA.prune(a,b);
		handler.dataB.prune(a,b);
	};
	this.parseData = function(data)
	{
		handler.parse(data);
	};
};
Ext.extend(AnnoJ.MaskTrack,AnnoJ.BrowserTrack,{})
