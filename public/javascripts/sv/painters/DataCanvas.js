/*
 * Canvas extension that adds data support and a few additional rendering options.
 * The canvas is designed to be bound to a list data structure that supports subset
 */
Ext.define('Sv.painters.DataCanvas',{
  extend : 'Sv.painters.BaseCanvas',
  scaler : 1.0,
	flippedX : false,
	flippedY : false,
	initComponent : function(){
	  this.callParent(arguments);
		var self = this;
		this.groups = (function()
		{
			var list = {};

			function exists(name)
			{
				return !(list[name] == undefined);
			};

			function add(name)
			{
				if (exists(name)) return;
				list[name] = true;
				self.styles.set(name);
			};

			function remove(name)
			{
				if (!exists(name)) return;
				delete list[name];
				self.styles.remove(name);
			};

			function clear()
			{
				list = {};
				self.styles.clear();
			};

			function getList()
			{
				return list;
			};

			function toggle(name, state)
			{
				list[name] = state ? true : false;
			};

			function active(name)
			{
				return list[name] ? true : false;
			};

			return {
				exists  : exists,
				add     : add,
				remove  : remove,
				clear   : clear,
				getList : getList,
				toggle  : toggle,
				active  : active
			};
		})()
	},
	//Scaler control functions
	setScaler : function(value, update)
	{
		this.scaler = parseFloat(value) || 0;
		if (this.scaler < 0) this.scaler = 0;
		if (update) this.paint();
	},
	getScaler : function()
	{
		return this.scaler;
	},
	//Plot flipping functions
	flipX : function(update)
	{
		this.flippedX = !this.flippedX;
		if (update) this.paint();
	},
	flipY : function(update)
	{
		this.flippedY = !this.flippedY;
		if (update) this.paint();
	},
	isFlippedX : function()
	{
		return this.flippedX;
	},
	isFlippedY : function()
	{
		return this.flippedY;
	}
})