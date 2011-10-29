//System Messenger component
AnnoJ.EditBox = function(id)
{
	var self = this;
	var currentTrack={};
	
	var body = new Ext.Element(document.createElement('DIV'));
  
	body.addCls('AJ_editbox');
	
	var innerHTML = {
		annoj : '',
		citation : '',
		message : ''
	};
	
	AnnoJ.EditBox.superclass.constructor.call(this,
	{
		title     : "Edit",
		iconCls   : 'silk_information',
		border    : false,
		autoScroll : true,
		contentEl : body, 
		//items	 : [body],   /// !!!Did NOT work with EXT 3.2.1 =  "cannot access property dom of undefined"
		buttons :
		[
			{
				xtype			: 'button',
				text      : 'Remove',
				tooltip 	: 'Delete this Gene',
				handler   : function()
				{
									  var obj = body.dom.childNodes[1]
					          var locusTag = obj.id.split("_edit")[0];
					          var answer = confirm("Are you sure you want to delete "+locusTag+"? "+
					                                "This action cannot be undone.");
					          if(answer){
					            AnnoJ.getGUI().EditBox.deleteLocusTag(locusTag);
					          }
					self.collapse();
					self.hide();
					AnnoJ.getGUI().TrackSelector.expand();
				}
			},
			{
				text 			: 'Cancel',
				tooltip 	: 'Close Edit Panel',
				handler 	: function()
				{
					self.collapse();
					self.hide();
					AnnoJ.getGUI().TrackSelector.expand();
				}
			},
       {
         text    	: 'Commit',
         tooltip 	: 'Save changes to database',
         handler 	: function()
					{
						table = body.dom.childNodes[1];
						var locus_tag = table.id.split("_edit");
						self.editGenome(table.childNodes,locus_tag[0]);
						self.collapse();
						self.hide();
					}
				}
		]
	});
	
	this.setTrack = function(track){
		currentTrack = track;
	};
	
	this.getTrack = function(){
		return currentTrack;
	}
	
	this.populateSelectBox = function(id){
		var track = currentTrack;
	  BaseJS.request(
		{
			url         : track.config.data,
			method      : 'GET',
			requestJSON : false,
			data        :
			{
				jrws : Ext.encode({
					method    : 'select',
					param     : {
						bioentry  : track.config.bioentry
					}
				})
			},
			success  : function(response)
			{
				d = response.data;
				var select = document.getElementById('addSelect')
				var hidden = document.createElement('input')
				hidden.setAttribute('type','hidden')
				hidden.value = id
				select.parentNode.appendChild(hidden)
				for(var x = 0; x < d.length; x++){
					select.options[x] = new Option(d[x],d[x]);     
				}
			}
		});	  
	};
	
	this.add = function(obj,locus_tag){
	  var track = currentTrack;
	  var changed = [];
	  var id = locus_tag.id.split("_edit")[0]
		
		for (var p = 0; p < obj.length; p++){
		  changed.push(obj[p].value)
		}
	  BaseJS.request(
		{
			url         : track.config.edit,
			method      : 'POST',
			requestJSON : false,
			data        :
			{
				jrws : Ext.encode({
					method    : 'add',
					bioentry  : track.config.bioentry,
					param     : {
					              id            : id,
					              term          : changed[0],
					              value         : changed[1],
					              seqfeature_id : changed[4]
					            }
				})
			},
			success  : function(response)
			{
				if (response.success)
				{
          var d = response.data;
          var select = document.getElementById('addSelect')
          parent = select.parentNode.parentNode
          parent.removeChild(select.parentNode);
                    
          AnnoJ.getGUI().EditBox.loadEdit(currentTrack.buildDesc(d,{'info': false}),currentTrack.config.id);
          self.fireEvent('editBoxCommit',id);
					currentTrack.lookupModel(id);
				}
				else
				{
					AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information. Server says: " + response.message);
				}
			},
			failure  : function(message)
			{
				AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information from the server");
			}
		});
	  
	};
	
	this.editGenome = function(data,locus_tag)
	{
    var changed = [];
	  //var track = '';
		// for (var x = 0; x < AnnoJ.config.tracks.length; x++){
		//   if(AnnoJ.config.tracks[x].id == currentTrack){
		//     track = x
		//   }
		// }
		var track = currentTrack
		
    for(var i=0;i < data.length; i++){
      if(data[i].childNodes){
        for(var c=0; c < data[i].childNodes.length; c++){
          if(data[i].childNodes[c].id && 
             data[i].childNodes[c].childNodes[0].value &&
             data[i].childNodes[c].childNodes[1].value){
               if(data[i].childNodes[c].childNodes[0].value == 
                  data[i].childNodes[c].childNodes[1].value){ continue;}
                else
                {
                  var ids = data[i].childNodes[c].id.split("_");
                  changed.push({'locus_tag'     :locus_tag,
                                'seqfeatureid'  :ids[0],
                                'termid'        :ids[1],
                                'rankid'        :ids[2],
                                'type'          :ids[ids.length - 1],
                                'locationid'    :ids[0],
                                'pos'           :ids[1],
                                'changed'       :data[i].childNodes[c].childNodes[0].value,
                                'original'      :data[i].childNodes[c].childNodes[1].value
                                });
               }
          }
        }
      }
    }
    if(changed.length == 0) { alert("No changed entries to commit"); return; }
    
		BaseJS.request(
		{
			url         : track.config.edit,
			method      : 'POST',
			requestJSON : false,
			data        :
			{
				jrws : Ext.encode({
					method    : 'edit',
					param     : changed,
					bioentry  : track.config.bioentry
				})
			},
			success  : function(response)
			{
				if (response.success)
				{
          
					AnnoJ.getGUI().TrackSelector.expand();
					// m = AnnoJ.getTrack('models');
					// m.refresh();
					// n = AnnoJ.getTrack('logging');
					// if(n){
					//   n.refresh();
					// }
          
				}
				else
				{
          AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information. Server says: " + response.message);
				}
			},
			failure  : function(message)
			{
				AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information from the server");
			}
		});
	}
	
	this.delGenomeItem = function(original,newData,db,locus_tag)
	{
		var ids = db.split("_");		
	  var id = locus_tag
		// var track = '';
		// for (var x = 0; x < AnnoJ.config.tracks.length; x++){
		//   if(AnnoJ.config.tracks[x].id == currentTrack){
		//     track = x
		//   }
		// }
		var track = currentTrack;
		BaseJS.request(
		{
			url         : track.config.edit,
			method      : 'POST',
			requestJSON : false,
			data        :
			{
				jrws : Ext.encode({
					method : 'delete',
					param  : {
					  locus_tag     : id,
  				  seqfeatureid  : ids[0],
						termid        : ids[1],
						rankid        : ids[2],
						type          : ids[ids.length - 1],
						locationid    : ids[0],
						pos           : ids[1],
						original      : original,
						changed       : newData,
  					bioentry  : track.config.bioentry
					}
				})
			},
			success  : function(response)
			{
				if (response.success)
				{
          var d = response.data;
          AnnoJ.getGUI().EditBox.loadEdit(AnnoJ.ModelsTrack.buildDesc(d,{'info': false}),AnnoJ.getTrack('models').config.id);
					currentTrack.lookupModel(id);
				}
				else
				{
					AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information. Server says: " + response.message);
				}
			},
			failure  : function(message)
			{
				AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information from the server");
			}
		});
	}
	
	this.deleteLocusTag = function(locusTag){
		// var track = '';
		// for (var x = 0; x < AnnoJ.config.tracks.length; x++){
		//   if(AnnoJ.config.tracks[x].id == currentTrack){
		//     track = x
		//   }
		// }
		var track = currentTrack
		BaseJS.request(
		{
			url         : track.config.edit,
			method      : 'POST',
			requestJSON : false,
			data        :
			{
				jrws : Ext.encode({
					method : 'deleteLocusTag',
					param  : {
					  locus_tag     : locusTag,
  					bioentry  : track.config.bioentry
					}
				})
			},
			success  : function(response)
			{
				if (response.success)
				{
					//           AnnoJ.getGUI().TrackSelector.expand();
					// m = AnnoJ.getTrack('models');
					// m.refresh();
					// n = AnnoJ.getTrack('logging');
					// if(n){
					//             n.refresh();
					//           }
				}
				else
				{
					AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information. Server says: " + response.message);
				}
			},
			failure  : function(message)
			{
				AnnoJ.getGUI().InfoBox.echo("Error: failed to retrieve gene information from the server");
			}
		});
	};
	

	
	this.loadEdit = function(obj,type){
    obj = {}
    body.update("<div class='waiting'>Loading...</div>");
    // if (typeof(obj) == 'object')
    // {
    //      // body.appendChild(obj); 
    //      //          var d = obj.parentNode.getElementsByTagName('div')
    //      //          Ext.get(d[0]).hide(true)
    //      self.expand();  
    //   return;
    // }
      self.expand();
      body.update(obj);
	}
	
	// This needs to be refactored
	this.buildDesc = function(msg){
	  var view = {info:true};
    // return msg
    // box = AnnoJ.getGUI().EditBox;
    box = self;
   // Set the id append depending if we're viewing the 
    // editor or the information panel
    var idScheme = (!view.info ? 'edit' : 'info');
  
    var table = document.createElement('table');
      table.setAttribute('id',msg.locus_tag+"_"+idScheme)
      
      var thead = document.createElement('thead');
      table.appendChild(thead);
      
      var buttons = new AnnoJ.ModelsTrackEdit();
  
      
      
      for (var x=0; x < msg.genbank.length; x++)
      {
        for(name in msg.genbank[x])
        { 
          var trTop = document.createElement('tr');
          var td1Top = document.createElement('td');
          td1Top.setAttribute('id',msg.genbank[x][name].sqv[0].seqfeatureId)
          var td2Top = document.createElement('td');
          var td3Top = document.createElement('td');
          var td4Top = document.createElement('td');
          var img = document.createElement('span');
          var delTop = document.createElement('span')
          delTop.setAttribute('class','.no-background .x-toolbar');
          if(!view.info){
            img.setAttribute('class','.no-background .x-toolbar');
            buttons.addQualifierButtons(img);
            img.setAttribute('id',name);
          }
          var term = document.createTextNode(name);
          td1Top.appendChild(term);
          td2Top.appendChild(img);
          td3Top.appendChild(delTop);
          td4Top.appendChild(document.createElement('span'));
          trTop.appendChild(td1Top);
          trTop.appendChild(td2Top);
          trTop.appendChild(td3Top);
          trTop.appendChild(td4Top);
          table.appendChild(trTop);
          for (var f = 0; f < msg.genbank[x][name].location.length; f++)
          {
            var term = document.createTextNode(name);
            var value = document.createTextNode(msg.genbank[x][name].location[f].value);
            var nameDesc = document.createTextNode(msg.genbank[x][name].location[f].name);
            ////lets just skip it
            // if(msg.genbank[x][name].location[f].name == "locus_tag"){
            //  continue;
            // }
            var blank = document.createElement("span");
          
                 
            var tr = document.createElement('tr');
            tr.setAttribute('id','tr'+getRandom());
            var td1 = document.createElement('td');
            var td2 = document.createElement('td');
            var td3 = document.createElement('td');
            var td4 = document.createElement('td')
            td3.setAttribute('id',msg.genbank[x][name].location[f].locationId+"_"+
                                  msg.genbank[x][name].location[f].name+"_"+
                                  msg.genbank[x][name].location[f].type);
            
                        if(!view.info){
                          var hidden = document.createElement('input');
                          hidden.setAttribute('value',value.textContent);
                          hidden.setAttribute('type','hidden');
                          
                          var del = document.createElement('span');
                          // buttons.addDelButtons(del,'Location');
                          
                          // var input = document.createElement('input');
            var input = new Ext.form.TextField({
              renderTo : td3,
              value : value.textContent,
              width : 85
            });
                          td3.appendChild(hidden);
                          td4.appendChild(del);
                        } 
                        else {
              td3.appendChild(value);
            }
  
            td1.appendChild(blank);
            td2.appendChild(nameDesc); 
            tr.appendChild(td1);
            tr.appendChild(td2);
            tr.appendChild(td3);
            tr.appendChild(td4);
            table.appendChild(tr);
          }
          
          for (var p = 0; p < msg.genbank[x][name].sqv.length; p++)
          {
            //             //lets just skip it
            // if(msg.genbank[x][name].sqv[p].name == "Locus_tag"){
            //  continue;
            // }
            var desc = document.createTextNode(msg.genbank[x][name].sqv[p].value);
            var nameDesc = document.createTextNode(msg.genbank[x][name].sqv[p].name);
            
            var blank = document.createElement("span");
            var tr = document.createElement('tr');
            tr.setAttribute('id','tr'+getRandom());
            var td1 = document.createElement('td');
            var td2 = document.createElement('td');
            var td4 = document.createElement('td');
           
            td1.appendChild(blank);
            td2.appendChild(nameDesc);
            var td3 = document.createElement('td');
            td3.setAttribute('id',msg.genbank[x][name].sqv[p].seqfeatureId+"_"+
                                  msg.genbank[x][name].sqv[p].termId+"_"+
                                  msg.genbank[x][name].sqv[p].rank+"_"+
                                  msg.genbank[x][name].sqv[p].type);
            
            if(!view.info){
              var hidden = document.createElement('input');
              hidden.setAttribute('value',desc.textContent);
              hidden.setAttribute('type','hidden');
              
              var del = document.createElement('span');
              del.setAttribute('class','.no-background .x-toolbar')
              buttons.addDelButtons(del,'Qualifier');
  
              
        if(desc.textContent.length > 30)
        {
          var input = new Ext.form.TextArea({
            renderTo : td3,
            value : desc.textContent,
            width : 145,
            height: 75,
            });
            input.doLayout;
        }
        else
        {
          var input = new Ext.form.TextField({
            renderTo : td3,
            value : desc.textContent,
            width : 130
            }); 
        }
        
              // var input = document.createElement('input');
              // input.setAttribute('type','text');
              // input.setAttribute('size','16');
              // input.value = desc.textContent;
              // 
              // if(desc.textContent == msg.locus_tag){ 
              //   continue;
              //   input = document.createTextNode(desc.textContent);
              //   del = blank;
              // }
              
              //td3.appendChild(input);
              td3.appendChild(hidden);
              td4.appendChild(del);
            } 
            else {
              td3.appendChild(desc);
            }
                
            tr.appendChild(td1);
            tr.appendChild(td2);
            tr.appendChild(td3);
            tr.appendChild(td4);
            table.appendChild(tr);
                
          }
        }
      }  
      // if(!view.info){
      //   table.appendChild(lastRow(msg,idScheme))
      // } 
      
      return table;
    
	};
	
	this.echo = function(msg)
	{
    self.expand();
		body.update(msg);

	};
};
Ext.extend(AnnoJ.EditBox,Ext.Panel,{})
