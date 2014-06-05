Ext.define('Sv.tracks.GenericFeatureTrack',{		
    extend : 'Sv.tracks.BrowserTrack',
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
			//Initialization
			var containerA = new Ext.Element(document.createElement('DIV'));
			var containerB = new Ext.Element(document.createElement('DIV'));

			containerA.addCls(self.clsAbove);
			containerB.addCls(self.clsBelow);
			
			self.searchURL = self.data+'search'
			//Force some styles
			containerA.setStyle('position', 'relative');
			containerB.setStyle('position', 'relative');
			containerA.setStyle('width', '100%');
			containerB.setStyle('width', '100%');

			if (self.single)
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
                Ext.define('FeatureSearchResult',{
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
      			model: 'FeatureSearchResult',
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

                var search = Ext.create("Ext.form.ComboBox",
                {
      			store       : ds,
      			valueField  : 'id',
      			width       : 350,
      			queryDelay  : 1000,
      			minChars    : 3,
      			hideTrigger : true,
      			pageSize    : 20,
      			emptyText   : 'Search Sequence Features...',
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
                               window.location = record.data.reload_url+"/"+record.data.bioentry_id+"?tracks[]=generic_feature_track&feature_id="+record.data.id+"&pos="+record.data.start
                           }

                       }
                  }
                });

                self.Toolbar.insert(4, new Ext.Toolbar.Spacer());
                self.Toolbar.insert(4, search);
            }

			//function to handle model clicks
			this.lookupModel = function(feature_id)
			{
				//box = AnnoJ.getGUI().EditBox;
		    box = AnnoJ.getGUI().InfoBox;
				box.show();
				box.expand();
				box.echo("<div class='waiting'>Loading...</div>");
				BaseJS.request(
				{
					url         : self.data+feature_id,
					method      : 'GET',
					requestJSON : false,
					data        :
					{
					  bioentry	: self.bioentry
					},
					success  : function(response)
					{
						if (response.success)
						{
		          var response_data = response.data;
		          //box.loadEdit( self.buildDesc(response_data,{'info': false}), self.id );
							//box.setTrack(self);

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
			};

			//Data handler and renderer
			var GenericFeature = (function()
			{
				var dataA = new GenericFeatureList();
				var dataB = new GenericFeatureList();

				function parse(data)
				{
		      // console.log(data)
					dataA.parse(data,true);
					dataB.parse(data,false);			
				};

				var canvasA = new Sv.painters.GenericFeatureCanvas({
					strand : '+',
					labels : self.showLabels,
					arrows : self.showArrows,
					scaler : self.slider * 2,
					boxHeight : self.boxHeight,
					boxHeightMax : self.boxHeightMax,
					boxHeightMin : self.boxHeightMin,
					boxBlingLimit : self.boxBlingLimit			
				});
				var canvasB = new Sv.painters.GenericFeatureCanvas({
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
				canvasA.setPixelBaseRatio(AnnoJ.pixels2bases(1));
				canvasB.setPixelBaseRatio(AnnoJ.pixels2bases(1));	
				canvasA.on('modelSelected', self.lookupModel);
				canvasB.on('modelSelected', self.lookupModel);


				function paint(left, right, bases, pixels)
				{
					var subsetA = dataA.subset2canvas(left, right, bases, pixels);
					var subsetB = dataB.subset2canvas(left, right, bases, pixels);
					canvasA.setData(subsetA);
					canvasB.setData(subsetB);

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
			this.getGenericFeature = function(){
				return GenericFeature;
			}
			//Data handling and rendering object
			var handler = GenericFeature;	

			//Zoom policies (dictate which handler to use)
			var policies = [
				{ index:0, min:1/100 , max:10/1   , bases:1   , pixels:1  , cache:10000   },
				{ index:1, min:10/1  , max:100/1  , bases:10  , pixels:1  , cache:100000  },
				{ index:2, min:100/1 , max:1000/1 , bases:100 , pixels:1  , cache:1000000 },
				{ index:3, min:1000/1 , max:10000/1 , bases:1000 , pixels:1 , cache:10000000 }
			];

			//Data series labels
			var labels = null;

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

			this.getPolicy = function(view)
			{
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

			//Track overrides

      // this.mask = function(m)
      // { 
      //  self.Frame.ext.addCls('masked')
      //  containerA.addCls('masked');
      //  containerB.addCls('masked');
      // }; //override masking to hide extra canvas divs
      // 
      // this.unmask = function()  
      // { 
      //  containerA.removeCls('masked');
      //  containerB.removeCls('masked');
      //  self.Frame.ext.removeCls('masked');
      // 
      // }; //override masking to hide extra canvas divs

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
