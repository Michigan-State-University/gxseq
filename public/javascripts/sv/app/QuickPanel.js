//Application description box
AnnoJ.QuickPanel = (function()
{
	var body = new Ext.Element(document.createElement('DIV'));
	body.addCls('AJ_panel');
			
	return function(userConfig)
	{
		var userConfig = Ext.apply(userConfig || {}, {
			contentEl  : body,
			autoScroll : true,
			border     : false
		}, {});
		
		AnnoJ.AboutBox.superclass.constructor.call(this, userConfig);

		this.update = function(msg)
		{
			body.update(msg);
		};
		this.addCitation = function(msg)
		{
			body.update(msg + body.dom.innerHTML);
		};
	};
})();
Ext.extend(AnnoJ.QuickPanel,Ext.Panel,{})
