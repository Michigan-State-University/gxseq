//Generic web application routines. Assumes that Ext libraries are available
var WebApp = (function()
{
	//Check that the browser is compatible
	function checkBrowser()
	{	
		if (Ext.isIE)
				{
					return false;
				}
				else
				{
					return true;
				}
	};

	//Bomb with a message to leave IE
	function bombBrowser()
	{
		var html = "";
		html += "<table style='margin:auto; margin-top:100px; font-family:arial; font-size:13px;'>";
		html += "<tr style='vertical-align:middle;'>";
		html += "<td style='padding-right:20px;text-align:center'>";
		html +=	"<a href='http://www.apple.com/safari/download/' target='blank'><img src='/images/browsers/Safari-icon.png' alt='Get Opera' /></a><br/>";
		html +=	"<a href='http://www.google.com/chrome' target='blank'><img src='/images/browsers/Chrome-icon.png' alt='Get Chrome' /></a><br/>";
		html +=	"<a href='http://www.mozilla.org/en-US/firefox/new/' target='blank'><img src='/images/browsers/Firefox-icon.png' alt='Get Firefox' /></a><br/>";
		html +=	"<a href='http://www.opera.com/download/' target='blank'><img src='/images/browsers/Opera-icon.png' alt='Get Opera' /></a><br/>";
		html += "</td><td>";
		html += "<h3>Unfortunately, this application is not compatible with your browser</h3>";
		html += "<p style='padding:10px 0px;'>If you are using Internet Explorer then please consider switching to a W3C compatible alternative:</p>";
		html += "<p style='padding:10px 0px;'>Otherwise, you probably need an update:</p>";
		html += "<ul style='list-style:circle; margin-left:20px; font-size:smaller'>";
		html += "<li>W3C compliant browsers embrace World Wide Web Consortium development standards.</li>";
		html += "<li>Standardization avoids cumbersome web solutions (as was the case in the 1990s).</li>";
		html += "<li>Standardization means more time to focus on design rather than chasing browser quirks.</li>";
		html += "<li>W3C compliance produces more accessible websites.</li>";
		html += "<li>W3C compliant browsers tend to have better Javascript engines.</li>";
		html += "<li>W3C compliance includes CSS compliance.</li>";
		html += "<li>Abandoning obsolete browsers leads to them being fixed or disappearing; a better outcome for all.</li>";
		html += "<li>Internet Explorer is slow to follow the direction of modern web-application design.</li>";
		html += "</ul>";
		html += "</td></tr></table>";

		document.body.innerHTML = html;
	};
	
	return {
		checkBrowser : checkBrowser,
		bombBrowser : bombBrowser,
	};
})();