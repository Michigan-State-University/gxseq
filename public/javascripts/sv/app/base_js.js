var BaseJS = (function()
{
	var emptyFunction = function() {};
	
	var defaultSyndication = {
		institution : {
			name : '',
			url  : '',
			logo : ''
		},
		engineer : {
			name  : '',
			email : ''
		},
		service : {
			title    : '',
			version  : '',
			description : '',
			request : {
				type : '',
				format : '',
				schema : ''
			},
			response : {
				type : '',
				format : '',
				schema : ''
			}
		}
	};
	
	var defaultRequest = {
		url : '',
		data : null,
		method : 'GET',
		success : emptyFunction,
		failure : emptyFunction,
		requestJSON : true,
		receiveJSON : true
	};
	
	//Conduct a syndication request
	function syndicate(params)
	{
		Ext.applyIf(params || {}, defaultRequest);
		//call request method
		request(
		{
			url : params.url || '',
			data : {
				jrws : Ext.encode({
					method : 'syndicate',
					param  : {
            bioentry : params.bioentry
					}
				})
			},
			requestJSON : false,
			receiveJSON : true,
			success : function(response)
			{
				Ext.applyIf(response.data || {}, defaultSyndication);
				params.success(response.data);
			},
			failure : params.failure || emptyFunction
		});
	};
	
	//Convert a syndication object to HTML
	function syndicationToHTML(syndication)
	{
		var s = {};
		
		Ext.apply(s, syndication || {}, defaultSyndication);
		
		var html = "<div style='padding:2px;'>";
		html += "<div><a href='"+s.institution.url+"'><img src='"+s.institution.logo+"' alt='Data provider institutional logo' /></a></div>";
		html += "<div><b>Provider: </b><a href='"+s.institution.url+"'>"+s.institution.name+"</a></div>";
		html += "<div><b>Contact: </b><a href='mailto:"+s.engineer.email+"'>"+s.engineer.name+"</a></div>";
		html += "<hr />";
		html += "<div><b>"+s.service.title+"</b></div>";
		html += "<div>"+s.service.description+"</div>";
		return html + "</div>";
	};
	
	//Convert an object to html
	function objectToHTML(obj)
	{
		var html = '<ul>';
		
		for (var param in obj)
		{
			if (!obj.hasOwnProperty(param)) continue;

			if (typeof(obj[param]) == 'string')
			{
				html += '<li><b>' + param + ':</b> ' + obj[param] + '</li>';
			}
			else 
			{
				html += objectToHTML(obj[param]);
			}
		}
		return html + '</ul>';
	};
	
	//Conduct a request
	function request(params)
	{
		Ext.applyIf(params || {}, defaultRequest);
		if (!params.url) return;
		if (params.method != 'GET' && params.method != 'POST') return;
		if (params.requestJSON)
		{
			params.data = {
				request : JSON.stringify(params.data)
			};
		}
		if(params.method == 'POST'){params.data.authenticity_token = AnnoJ.config.auth_token;}
		Ext.Ajax.request(
		{
			url : params.url,
			method : params.method,
			params : params.data,
			failure : function(response, options)
			{
				params.failure('Communication error: ' + response.responseText);
			},
			success : function(response, options)
			{
				//Process an error if there is no server response at all
				if (!response)
				{
					params.failure('Server error: no response');
					return;
				}
				
				//Parse JSON if required
				if (params.receiveJSON)
				{
					try {
						response = JSON.parse(response.responseText);
					}
					catch (ex) {
						params.failure('Illegal JSON string: ' + response.responseText);
						return;
					}
				
					//Process an error if the server demands it
					if (response.success == false)
					{
						params.failure(response.message || 'unspecified server error');
						return;
					}
					
					//To get the far, everything worked OK
					params.success(response);
				}
				else
				{
					params.success(response.responseText);
				}
			}
		});
	};
	return {
		syndicate : syndicate,
		toHTML : syndicationToHTML,
		request : request
	};
})();
