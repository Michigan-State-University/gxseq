//Application description box
//TODO: Remove unused JS from SV
AnnoJ.Bugs = (function()
{
	var body = Ext.get(document.createElement('DIV'));
	body.addCls('AJ_bugs');
	
	var buglist = Ext.get(document.createElement('DIV'));
	
	//get this working for remote implementers (cross domain issue)
	/*Ext.onReady(function()
	{
		Ext.Ajax.request(
		{
			url : 'http://neomorph.salk.edu/~julian/bugs.php',
			method : 'GET',
			failure : function(msg) {
				Ext.Msg.alert('Error', msg);
			},
			success : function(response)
			{
				buglist.update(response.responseText);
			}
		});
	});*/
	
	var report = new Ext.form.TextArea();
	
	/*var button = new Ext.Button(
	{
		text : 'Send to Julian',
		iconCls : 'email_go',
		handler : function()
		{
			var txt = report.getValue();
			if (!txt) return;

			button.hide();
			report.mask("<div class='waiting'>Sending</div>");
			
			Ext.Ajax.request(
			{
				url : 'http://neomorph.salk.edu/~julian/bugs.php',
				method : 'GET',
				failure : function() {
					console.log('error');
					button.show();
					report.unmask();
					Ext.Msg.alert('Error', 'Failed to send message to server');
				},
				success : function(response)
				{
					console.log('success');
					console.log(response);
					buglist.update(response);
					button.show();
					report.unmask();
				}
			});				
		}
	});*/
	
	buglist.appendTo(body);
	//report.appendTo(body);
	//button.appendTo(body);
			
	return function()
	{
		AnnoJ.AboutBox.superclass.constructor.call(this, {
			title      : 'Bugs',
			iconCls    : 'silk_bug',
			border     : false,
			contentEl  : body,
			autoScroll : true
		});
	};
})();
Ext.extend(AnnoJ.Bugs,Ext.Panel,{})
