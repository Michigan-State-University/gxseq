Ext.define('Sv.tracks.ModelsTrack',{
		
    extend : 'Sv.tracks.BrowserTrack',
		
		///////////////////////////
		// Public members
		///////////////////////////
    single     : false,
    searchBox : true,
    clsAbove  : 'models_forward',
    clsBelow  : 'models_reverse',
    slider    : 0.5,
    showLabels : true,
    showArrows : true,
    labelPos : 'left',
    boxHeight : 14,
    boxHeightMax : 24,
    boxHeightMin : 1,
    boxBlingLimit : 6,
		
    initComponent : function(){

      this.callParent(arguments);
      var self = this;
      self.searchURL = self.data

			
			///////////////////////////
			// Private members
			///////////////////////////
			
      //Initialization
      var containerA = new Ext.Element(document.createElement('DIV'));
      var containerB = new Ext.Element(document.createElement('DIV'));
			
      containerA.addCls(self.clsAbove);
      containerB.addCls(self.clsBelow);
      
      //styles
      containerA.setStyle('position', 'relative');
      containerB.setStyle('position', 'relative');
      containerA.setStyle('width', '100%');
      containerB.setStyle('width', '100%');
      if (self.config.single)
      {
          containerA.setStyle('height', '100%');//self.Canvas.ext.getHeight());
          containerB.setStyle('display', 'none');
      }
      else
      {
          containerA.setStyle('height', '49%');
          containerB.setStyle('height', '49%');
          containerA.setStyle('borderBottom', 'dotted black 1px');
      }
      containerA.appendTo(self.Canvas.ext);
      containerB.appendTo(self.Canvas.ext);

      //Set up the search box (if required)
      if (self.searchBox)
      {
          Ext.define('GeneSearchResult',{
              extend : 'Ext.data.Model',
              fields: [
               {name: 'id', type:'int'},
			   {name: 'type', type:'string'},
			   {name: 'match', type:'string'},
			   {name: 'bioentry', type: 'string'},
			   {name: 'bioentry_id', type: 'int'},
			   {name: 'start', type: 'int'},
			   {name: 'end', type: 'int'},
			   {name: 'description', type: 'string'},
			   {name: 'reload_url',type:'string'}
              ]
          });
          
          var ds = Ext.create('Ext.data.Store',{
			      model: 'GeneSearchResult',
			      pageSize : 20,
			      proxy : {
			        type : 'ajax',
    		      url : self.searchURL,
    			    reader:{
    			      type : 'json',
    			      root : 'rows',
    			      totalProperty : 'count',
    			      id : 'id'
    			    },
    			    extraParams : {
    			      annoj_action  : 'lookup',
    			      bioentry      : self.bioentry
    			    }
			},

          });

          //Custom rendering Template
          var resultTpl = new Ext.XTemplate(
              '<tpl for=".">',
              '<div style="float:left"><b>{type}:</b>({start}-{end})</div><div style="float:right"><b>{bioentry}</b></div><br/>',
              '{match}',
              '<span>{description}</span>',
              '</tpl>'
          );

          var search = new Ext.form.ComboBox(
          {
			      store       : ds,
			      valueField  : 'id',
			      width       : 350,
			      queryDelay  : 1000,
			      minChars    : 3,
			      triggerAction : 'query',
			      pageSize    : 20,
			      emptyText   : 'Search Gene Features...',
			      listConfig  : {
			      loadingText  : 'Searching...',
			      getInnerTpl: function() {
			        var tpl = '<div class="drop_list"><div style="float:left"><b>{type}:</b>({start}-{end})</div><div style="float:right"><b>{bioentry}</b></div><br/>'+
                    '{match}'+
                    '<span>{description}</span></div>';
                    return tpl;
			        }
			      },			
            listeners : {
                
                beforequery:function(queryEvent){
                    //Hack fix for missing query param: http://www.sencha.com/forum/showthread.php?134592-EXTJSIV-2470-4.0.1-ComboBox-not-issuing-queryParam-on-paging-requests
                    queryEvent.combo.store.proxy.extraParams.query = queryEvent.combo.getValue();
                },
                change:function(combo){
                    combo.store.currentPage = 1;
                },
                select : function(box, items)
                 {
                     record = items[0] //we only allow single selection
                     //Same sequence
                     if(self.bioentry==record.data.bioentry_id)
                     {
                         var loc = AnnoJ.getLocation();
                         //loc.assembly = record.data.assembly;
                         loc.position = parseInt(record.data.start);
                         AnnoJ.setLocation(loc);
                         self.fireEvent('browse', loc);
                         self.lookupModel(record.data.id)
                         this.collapse();
                     }
                     //different sequence, need to load with new location
                     else
                     {
                         window.location = record.data.reload_url+"/"+record.data.bioentry_id+"?tracks[]=models_track&gene_id="+record.data.id+"&pos="+record.data.start
                     }
                 }
            }
          });
             
          self.Toolbar.insert(4, new Ext.Toolbar.Spacer());
          self.Toolbar.insert(4, search);
      }
	
      //Data handler and renderer
      var Models = (function()
      {
          var dataA = new ModelsList();
          var dataB = new ModelsList();

          function parse(data)
          {
              dataA.parse(data,true);
              dataB.parse(data,false);
          };

          var canvasA = new Sv.painters.ModelsCanvas({
              strand : '+',
              labels : self.showLabels,
              arrows : self.showArrows,
              scaler : self.slider * 2,
              boxHeight : self.boxHeight,
              boxHeightMax : self.boxHeightMax,
              boxHeightMin : self.boxHeightMin,
              boxBlingLimit : self.boxBlingLimit           
          });
          var canvasB = new Sv.painters.ModelsCanvas({
              strand : '-',
              labels : self.showLabels,
              arrows : self.showArrows,
              scaler : self.slider * 2,
              boxHeight : self.boxHeight,
              boxHeightMax : self.boxHeightMax,
              boxHeightMin : self.boxHeightMin,
              boxBlingLimit : self.boxBlingLimit           
          });

          canvasA.setContainer(containerA.dom);
          canvasB.setContainer(containerB.dom);
					canvasA.on('modelSelected', self.lookupModel,self);
		      canvasB.on('modelSelected', self.lookupModel,self);
					
          function paint(left, right, bases, pixels)
          {
              var subsetA = dataA.subset2canvas(left, right, bases, pixels);
              var subsetB = dataB.subset2canvas(left, right, bases, pixels);
              canvasA.setData(subsetA);
              canvasB.setData(subsetB);
              canvasA.setPixelBaseRatio(bases/pixels);
              canvasB.setPixelBaseRatio(bases/pixels);
              canvasA.paint();
              canvasB.paint();
              var list = canvasA.groups.getList();

              for (var series in list)
              {
                  addLabel(series);
              }

              list = canvasB.groups.getList();

              for (var series in list)
              {
                  addLabel(series);
              }
          };

          return {
              dataA : dataA,
              dataB : dataB,
              canvasA : canvasA,
              canvasB : canvasB,
              parse : parse,
              paint : paint
          };      
      })();

      //Data handling and rendering object
      var handler = Models;   

      //Zoom policies (dictate which handler to use)
      var policies = [
          { index:0, min:1/100 , max:10/1   , bases:1   , pixels:1  , cache:10000   },
          { index:1, min:10/1  , max:100/1  , bases:10  , pixels:1  , cache:100000  },
          { index:2, min:100/1 , max:1000/1 , bases:100 , pixels:1  , cache:1000000 },
          { index:3, min:1000/1 , max:10000/1 , bases:1000 , pixels:1 , cache:10000000 }
      ];

      //Data series labels
      var labels = null;

			///////////////////////////
			// Private methods
			///////////////////////////
			
      //Add series name to context menu (checkbox controls series visibility)
      function addLabel(name)
      {
          if (!labels)
          {
              self.contextMenu.addItems(['-','Series']);
              labels = {};
          }

          if (labels[name] == undefined)
          {
              labels[name] = true;

              self.contextMenu.addItems([
                  new Ext.menu.CheckItem(
                  {
                      text    : name,
                      checked : true,
                      handler : function()
                      {
                          handler.canvasA.groups.toggle(name, !this.checked);
                          handler.canvasB.groups.toggle(name, !this.checked);
                          handler.canvasA.refresh();
                          handler.canvasB.refresh();
                      }
                  })
              ]);
          }
      };

			///////////////////////////
			// Privileged Methods
			///////////////////////////
			
			this.getPolicy = function(view){
	         var ratio = view.bases / view.pixels;

	         for (var i=0; i<policies.length; i++)
	         {
	             if (ratio >= policies[i].min && ratio < policies[i].max)
	             {   
	                 return policies[i];
	             }
	         }
	         return null;
	    };
	    this.getModels = function(){
          return Models;
      };
      // this.mask = function(m){ 
      //          self.Frame.ext.addCls('masked')
      //          containerA.addCls('masked');
      //          containerB.addCls('masked');//override masking to hide extra canvas divs
      //      };
      //      this.unmask = function()  
      //      { 
      //          containerA.removeCls('masked');
      //          containerB.removeCls('masked');
      //          self.Frame.ext.removeCls('masked');//override masking to hide extra canvas divs
      //      };
	    this.rescale = function(f)
	    {
	        var f = parseFloat(f*2) || 0;
	        handler.canvasA.setScaler(f);
	        handler.canvasB.setScaler(f);
	        if(self.isFrameMasked())return;
	        handler.canvasA.refresh();
	        handler.canvasB.refresh();
	    };
	    this.clearCanvas = function()
	    {
	        handler.canvasA.clear();
	        handler.canvasB.clear();
	    };
	    this.paintCanvas = function(l,r,b,p)
	    {
	        if(self.isFrameMasked())return;
	        handler.paint(l,r,b,p);
	    };
	    this.refreshCanvas = function()
	    {
	        if(self.isFrameMasked())return;
	        handler.canvasA.refresh();
	        handler.canvasB.refresh();
	    };
	    this.resizeCanvas = function()
	    {
	        if(self.isFrameMasked())return;
	        handler.canvasA.refresh();
	        handler.canvasB.refresh();
	    };
	    this.clearData = function()
	    {
	        handler.dataA.clear();
	        handler.dataB.clear();
	    };
	    this.pruneData = function(a,b)
	    {
	        handler.dataA.prune(a,b);
	        handler.dataB.prune(a,b);
	    };
	    this.parseData = function(data)
	    {
	        handler.parse(data);
	    };
			
    },

		///////////////////////////
		// Public Methods
		///////////////////////////
		//function to handle model clicks
    lookupModel: function(id){
      box = AnnoJ.getGUI().InfoBox;
      box.show();
      box.expand();
      box.echo("<div class='waiting'>Loading...</div>");
      BaseJS.request(
      {
         url         : this.data,
         method      : 'GET',
         requestJSON : false,
         data        :
         {
             jrws        : Ext.encode({
                 method  : 'describe',
                 id      : this.id,
                 param   : {
                     id          : id,
                     bioentry    : this.bioentry
                 }
             })
         },
         success  : function(response)
         {
             if (response.success)
             {
                var response_data = response.data;
                box.echo(response_data.text);
                box.setTitle(response_data.title);

             }
             else
             {
                box.setTitle("error")
                box.echo(response.message);
             }
         },
         failure  : function(message)
         {
            box.setTitle("error")
            box.echo("Error: failed to retrieve gene information:<br/>"+message);
         }
      });
    },
    getConfig: function(){
      var track = this;
      return {
        id : track.id,
        name : track.name,
        data : track.data,
        height : track.height,
        scale : track.scale,
        showControls : track.showControls,
      }
    }
});

 // function getRandom() {
 //     var chars = "0123456789ABCDEFGHIJKLMNlmnopqrstuvwxyz";
 //     var string_length = 8;
 //     var randomstring = '';
 //     for (var i=0; i<string_length; i++) {
 //         var rnum = Math.floor(Math.random() * chars.length);
 //         randomstring += chars.substring(rnum,rnum+1);
 //     }
 //     return randomstring;
 //  }
 
 // this.addLocusTag = function(obj){
 //   Ext.ns('Term');
 //   
 //   Term.comboConfig = {
 //     xtype:'combo',
 //     id:'feature',
 //     valueField:'termID',
 //     anchor: '-15',
 //     hiddenName:'termID',
 //     displayField:'termName',
 //     triggerAction:'all',
 //     minChars:2,
 //     forceSelection:true,
 //     enableKeyEvents:true,
 //     resizable:false,
 //     minListWidth:90,
 //     allowBlank:false,
 //     // store getting items from server
 //     store:new Ext.data.JsonStore({
 //         id        :'termID',
 //         root      :'data',
 //         fields:[
 //             {name:'termID', type:'int'},
 //             {name:'termName', type:'string'}
 //         ],
 //         url:'../edits/term/1',
 //         baseParams:{
 //          field :"name"
 //         }
 //     }),
 // 
 //     // concatenate last and first names
 //      tpl:'<tpl for="."><div class="x-combo-list-item">{termName}</div></tpl>',
 // 
 //     // listeners
 //     listeners:{
 //         // sets raw value to concatenated last and first names
 //          select:function(combo, record, index) {
 //             this.setRawValue(record.get('termName'));
 //     },
 // 
 //         // repair raw value after blur
 //         blur:function() {
 //             var val = this.getRawValue();
 //             this.setRawValue.defer(1, this, [val]);
 //         },
 // 
 //         // set tooltip and validate 
 //         render:function() {
 //             this.el.set(
 //                 {qtip:'Type at least ' + this.minChars + ' characters to search for Term name'}
 //             );
 //             this.validate();
 //         },
 // 
 //         // requery if field is cleared by typing
 //         keypress:{buffer:100, fn:function() {
 //             if(!this.getRawValue()) {
 //                 this.doQuery('', true);
 //             }
 //         }}
 //     },
 // 
 //     // label
 //     fieldLabel:'Feature'
 //    };
 //    
 //    // ---- Extending vTypes with a numeric value ---- //
 //    Ext.form.VTypes["numeric"] = /\d/;
 //    Ext.form.VTypes["numericText"] = "This field can only contain numbersl";
 //    //  ---------------------------------------------- //
 //    
 //   
 //   var formPanel = new Ext.form.FormPanel({
 //     id:'formanchor-form',
 //     labelWidth:50,
 //     bodyStyle:'padding:15px',
 //     border:false,
 //     frame:true,
 //     // Monitor Remote Config validations
 //     monitorValid:true,
 //     // ------------------------------ //
 //     items:[{
 //       xtype:'textfield',
 //       id:'gene_locus_tag',
 //       fieldLabel:'Locus Tag',
 //       name:'locus_tag',
 //       anchor:'-15',
 //       allowBlank:false,
 //       value:''
 //      },
 //        Term.comboConfig
 //      ,{
 //        xtype:'textfield',
 //        id: 'gene_start_location',
 //        fieldLabel:'Start',
 //        name:'location_start',
 //        anchor:'-15',
 //        allowBlank:false,
 //        value:'',
 //        vtype:'numeric'
 //      },{
 //        xtype:'textfield',
 //        id:'gene_end_location',
 //        fieldLabel:'End',
 //        name:'location_end',
 //        anchor:'-15',
 //        allowBlank:false,
 //        value:'',
 //        vtype:'numeric'
 //        },
 //        ],
 //        buttons:[{
 //          text:'Go',
 //          formBind:true,
 //          handler:function(){
 //            var locus_tag = Ext.get('gene_locus_tag').dom.value
 //            var feature = Ext.get('feature').dom.value
 //            var start = Ext.get('gene_start_location').dom.value
 //            var end = Ext.get('gene_end_location').dom.value
 //            createNew(locus_tag,feature,start,end);
 //            var el = Ext.get('formanchor-win').destroy();
 //          }
 //        },{
 //          text:'Cancel',
 //          handler:function(){
 //            var el = Ext.get('formanchor-win').destroy();
 //          }
 //          }]
 //        });
 //        
 //      var win = new  Ext.Window({
 //             id:'formanchor-win',
 //             x: 500,
 //             y: 300,
 //             width:290,
 //             height:220,
 //             minWidth:290,
 //             minHeight:220,
 //             plain:true,
 //             title:'Add Gene',
 //             layout:'fit',
 //             border:false,
 //             closable:true,
 //             items:formPanel
 //       });
 //        
 //       win.show();
 //       
 // };
 
 // function createNew(tag,feature,start,end){
 //   box = AnnoJ.getGUI().EditBox;
 //     box.show();
 //     box.expand();
 //     box.setTrack(self);
 //     box.echo("<div class='waiting'>Loading...</div>");
 //   BaseJS.request(
 //     {
 //         url         : self.config.edit,
 //         method      : 'POST',
 //         requestJSON : false,
 //         data        :
 //         {
 //             jrws : Ext.encode({
 //                 method : 'addGene',
 //                 param  : {
 //                     locus_tag           : tag,
 //                     feature             : feature,
 //                     location_start      : start,
 //                     location_end        : end,
 //                     bioentry            : self.config.bioentry
 //                 }
 //             })
 //         },
 //         success  : function(response)
 //         {
 //             if (response.success)
 //             {
 //          var response_data = response.data;
 //          box.loadEdit( self.buildDesc(response_data,{'info': false}), self.config.id );
 //          box.setTitle("Edit: "+tag)
 //                 self.refresh();
 // 
 //             }
 //             else
 //             {
 //          box.echo("Error: failed to retrieve gene information. Server says: " + response.message);
 //             }
 //         },
 //         failure  : function(message)
 //         {
 //        box.echo("Error: failed to retrieve gene information from the server");
 //         }
 //     });
 // }
