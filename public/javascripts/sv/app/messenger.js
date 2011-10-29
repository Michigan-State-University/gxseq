//System Messenger component
AnnoJ.Messenger = (function()
{
	var body = new Ext.Element(document.createElement('DIV'));
	body.addCls('AJ_system_messages');
	
	function clear() {
		body.update('');
	};
	
	function alert(message, type, important)
	{
		if (!type || (type != 'error' && type != 'warning' && type != 'notice')) type = 'notice';
		
		body.update("<div class='AJ_system_"+type+"'>" + message + "</div>" + body.dom.innerHTML);
		
		/*
		if (important)
		{
			//Accordion.ext.expand();
		}
		if (Accordion.ext.isVisible())
		{
			//Messenger.ext.expand();
		}
		*/
	};
	
	function error(message)
	{
		if (console) console.trace();
		alert(message, 'error', true);
	};
	
	function warning(message)
	{
		if (console) console.trace();
		alert(message, 'warning', true);			
	};
	
	function notice(message, important)
	{
		alert(message, 'notice', important || false);
	};
	
	return function()
	{
		AnnoJ.Messenger.superclass.constructor.call(this,
		{
			title      : 'System Messages',
			iconCls    : 'silk_terminal',
			autoScroll : true,
			border     : false,
			contentEl  : body
		});
		this.clear = clear;
		this.alert = alert;
		this.error = error;
		this.warning = warning;
		this.notice = notice;
	};
})();
Ext.extend(AnnoJ.Messenger, Ext.Panel,{});
