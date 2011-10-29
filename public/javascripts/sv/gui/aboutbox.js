//Application description box
AnnoJ.AboutBox = (function()
{
	var info = {
		//logo      : "<a href='http://www.annoj.org'><img src='http://neomorph.salk.edu/epigenome/img/Anno-J.jpg' alt='Anno-J logo' /></a>",
		logo      : "",
		version   : 'Beta 1.1',
		engineer  : 'Julian Tonti-Filippini',
		contact   : 'tontij01(at)student.uwa.edu.au',
		copyright : '&copy; 2008 Julian Tonti-Filippini',
		website   : "<a href='http://www.annoj.org'>http://www.annoj.org</a>",
		//tutorial  : "<a target='new' href='http://neomorph.salk.edu/index.html'>SALK example</a>",
		license   : ""
	};
	var body = new Ext.Element(document.createElement('DIV'));
	
	var html = 
		"<div style='padding-bottom:10px;'>" + info.logo + "</div>" +
		"<table style='font-size:10px';>" + 
		"<tr><td><div><b>Version: </b></td><td>"   + info.version   +"</div></td></tr>" +
		"<tr><td><div><b>Engineer: </b></td><td>"  + info.engineer  +"</div></td></tr>" +
		"<tr><td><div><b>Contact: </b></td><td>"   + info.contact   +"</div></td></tr>" +
		"<tr><td><div><b>Copyright: </b></td><td>" + info.copyright +"</div></td></tr>" +
		"<tr><td><div><b>Website: </b></td><td>"   + info.website   +"</div></td></tr>" +
		"<tr><td><div><b>License: </b></td><td>"   + info.license   +"</div></td></tr>" +
		"<tr><td><div><b>Tutorial: </b></td><td>"  + info.tutorial  +"</div></td></tr>" +		
		"</table>"
	;

	body.addCls('AJ_aboutbox');
	body.update(html);
	
	function addCitation(c)
	{
		body.update(c + html);
	};
		
	return function()
	{
		AnnoJ.AboutBox.superclass.constructor.call(this, {
			title      : 'Citation',
			iconCls    : 'silk_user_comment',
			border     : false,
			contentEl  : body,
			autoScroll : true
		});
		this.info = info;
		this.addCitation = addCitation;
	};
})();
// Ext.extend(AnnoJ.AboutBox, Ext.Panel);
Ext.extend(AnnoJ.AboutBox,Ext.Panel,{})