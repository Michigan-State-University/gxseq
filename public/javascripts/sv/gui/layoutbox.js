AnnoJ.LayoutBox = function()
{
	var self = this;
	var body = new Ext.Element(document.createElement('DIV'));
	body.addCls('AJ_layoutbox');
	self.loadPath = 'not_set';
	
	AnnoJ.LayoutBox.superclass.constructor.call(this,
	{
		title     : 'Layouts',
		iconCls   : 'silk_application_side_list',
		border    : false,
		contentEl : body,
		hideCollapseTool: true,
		autoScroll : true
	});	
	
	var layouts = new Array();
	
	this.setLoadPath = function(path){
	  self.loadPath = path;
	};
	this.refresh = function()
	{
		loadLayouts();
	}
	
	this.update = function(msg)
	{		
		if (typeof(msg) == 'object')
		{
      body.update();
      body.appendChild(msg);
			return;
		}
		body.update(msg);
	};
	
	function setEmpty(){
		self.update("<br/><h1>You have no saved layouts</h1><br/><hr/><br/><br/><p style='float:left'>Try clicking the save icon below </p><div class='x-tool x-tool-save' style='cursor:auto;float:left'></div>")
	};
	
	function setData(data){
		if(data.length == 0)
		{
			setEmpty();
		}
		else{
			text = "<br/>";
			text += "<h1 style='padding-left:5px;'> Selecting a layout from the list below will reload the browser with the new layout</h1>";
			text += "<br/>";
			text += "<ul>";
			Ext.each(data, function(layout){
				text += "<div style='margin-left:3px;' class='x-panel-header'><a href="+AnnoJ.config.refresh_path+"?layout_id="+layout.track_layout.id+">"+layout.track_layout.name+"</a></div>";
			});
			text +=	"<div style='margin-left:3px;' class='x-panel-header'><a href="+AnnoJ.config.refresh_path+"?default=true>Default Layout</a></div>";
			text += "</ul>";
			self.update(text)
		}
	};
	
	function loadLayouts(){
		self.update("loading layouts...");
		BaseJS.request(
		{
			url         : self.loadPath,
			method      : 'GET',
			requestJSON : false,
		data : {},
			success  : function(response)
			{
				setData(response);
			}
		});
		
	};
	
	this.on("render", function(){
		loadLayouts();
	});
};
Ext.extend(AnnoJ.LayoutBox,Ext.Panel,{})













