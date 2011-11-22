//System Messenger component
AnnoJ.InfoBox = function()
{
	var self = this;
	
	var body = new Ext.Element(document.createElement('DIV'));
	body.addCls('AJ_infobox');
	  
	AnnoJ.InfoBox.superclass.constructor.call(this,
	{
		title     : 'Information',
		iconCls   : 'silk_information',
		border    : false,
		contentEl : body,
		autoScroll : true,
    buttons : [
    { 
      xtype : 'button',
      text  : 'Close',
      tooltip: 'Close this window',
      handler: function()
      {
        self.hide();
        self.collapse();
      }
    }
    ]
	});
	
	this.log = function(msg)
	{
		self.expand();
		
    if (typeof(msg) == 'object')
    {
          body.update();
          body.appendChild(msg);
     return;
    }
    body.update(msg);
	};
	
	this.echo = function(msg)
	{
		self.expand();
		if (typeof(msg) == 'object')
		{
      body.update();
      body.appendChild(msg);
			return;
		}
    body.update(msg);    
	};	
	
	this.refresh = function(msg)
	{
		self.expand();
		self.refresh();
		
		if (typeof(msg) == 'object')
		{
      body.update();
      body.appendChild(msg);
			return;
		}
		body.update(msg);
	};
	  
};
Ext.extend(AnnoJ.InfoBox,Ext.Panel,{})
