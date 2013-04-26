// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function remove_fields(link) {
  if($(link).previous("input[type=hidden]") && $(link).previous("input[type=hidden]").value=='false'){
		$(link).previous("input[type=hidden]").value = "1";
  	$(link).up(".nested-fields").hide();
	}else{
		$(link).up(".nested-fields").remove();
	}
	
}

function add_fields(link, association, content,render) {
	if(render=='below'){
		var new_id = new Date().getTime();
	  var regexp = new RegExp("new_" + association, "g")
	  $(link).up(".new-fields").insert({
			after: content.replace(regexp, new_id)
		});
	}else{
		var new_id = new Date().getTime();
	  var regexp = new RegExp("new_" + association, "g")
	  $(link).up(".new-fields").insert({
			before: content.replace(regexp, new_id)
		});
	}
}

document.on('ajax:before', 'a.favorite', function(e, item) {
	//item.update("<img src='/images/loading.gif'></img>")
	item.update(item.getAttribute('data-loading'))
});

document.on("change", "*[data-onchange]", function(event, element) {
  var onchange_url = element.readAttribute('data-onchange');
	var param = element.readAttribute('data-params');
	var with_param = element.readAttribute('data-with');
	var changeElement = element.readAttribute('data-element');
	var val = element.value;
	if(changeElement)
		changeElement = $(changeElement)
	else
		changeElement = element.up('onchange-field')
	
	if(with_param && param)
		param = param +"&"+with_param+"="+val;
	else
		param = with_param+"="+val;
		
	if(param)
		param = param.toQueryParams();
	else
		param = {};
	changeElement.innerHTML="<img src='../images/loading.gif'></img>";
	new Ajax.Request(onchange_url, {
    method: "get",
		parameters: param,
    onComplete: function(request) {changeElement.innerHTML=request.responseText},
  });
});