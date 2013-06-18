//TODO: Convert Microarray and Reads track  to Histogram and Reads track
Ext.define('DataPeak',{
 extend: 'Ext.data.Model',
 fields: [
    'id',
    'link',
    'pos',
    'val'
]
});

Ext.define("Sv.tracks.MicroarrayTrack",{
  extend:"Sv.tracks.BrowserTrack",
  single   : false,
	clsAbove : 'AJ_above',
	clsBelow : 'AJ_below',
	color_above: '800000',
	color_below: '003300',
	peaks: false,
	initComponent : function(){
	    this.callParent(arguments);
	    var self = this;
      self.addEvents({
        'viewMaxChanged' : true,
        'trackMaxChanged': true
      });
      	this.absMax =0;
      	this.peaks=[];
        this.trackMax=1;
        this.allTrackMax=2;
        this.viewMax = 3;
        this.allViewMax=4;
        this.scaleSource = -4;
      	//Initialize the DOM elements
      	var containerA = new Ext.Element(document.createElement('DIV'));
      	var containerB = new Ext.Element(document.createElement('DIV'));

      	containerA.addCls(self.clsAbove);
      	containerB.addCls(self.clsBelow);

      	//Force some styles
      	containerA.setStyle('position', 'relative');
      	containerB.setStyle('position', 'relative');
      	containerA.setStyle('width', '100%');
      	containerB.setStyle('width', '100%');
      
      	if (self.single)
      	{
      		containerA.setStyle('height', '100%');
      		containerB.setStyle('height', '0%');	
      		//containerA.setStyle('borderBottom', 'dotted black 1px');
      		containerB.setStyle('display', 'none');
      	}
      	else
      	{
      		containerA.setStyle('height', '50%');
      		containerB.setStyle('height', '50%');
      		//containerA.setStyle('borderBottom', 'dotted black 1px');
      	}
      	containerA.appendTo(self.Canvas.ext);
      	containerB.appendTo(self.Canvas.ext);
      	
        this.getViewMax = function(location){
          var edges = self.DataManager.getEdges()
          var newMax = handler.dataA.getMaxY(edges.g1,edges.g2).toFixed(2)
          self.setViewMax(newMax);
          //console.log(self.name+": set viewmax:"+newMax);
          return newMax;
        }
        //get the max that we will use to draw
        this.getCurrentMax=function(left,right){
          var newScale = 1;
          switch(self.scaleSource)
          {
          // case -1:
          //   newScale = self.trackMax;
          //   break;
          // case -2:
          //   newScale = self.allTrackMax;
          //   break;
          case -3:
            newScale = self.viewMax;
            break;
          case -4:
            newScale = self.allViewMax;
            break;
          default:
            newScale = self.scaleSource;
          }
          return newScale;
        }
        
        this.setViewMax = function(newMax){
          if(handler==Histogram){
            self.viewMax = newMax;
            self.scales.getById(3).set('name','This Track ('+newMax+')');
            if(self.scaleSource==-3){
              self.scaleSourceSelect.setRawValue('This Track ('+newMax+')');
            }
          }
        }
        this.setAllViewMax = function(newMax){
          if(handler==Histogram){
            self.allViewMax = newMax;
            self.scales.getById(4).set('name','All Tracks ('+newMax+')');
            if(self.scaleSource==-4){
              self.scaleSourceSelect.setRawValue('All Tracks ('+newMax+')');
            }
          }
        }

        // Setup the scale select list
        this.scales = Ext.create('Ext.data.Store', {
            fields: ['id', 'name', 'val'],
            data : [
                // {"id":1,"name":"This Track","val":-1},
                // {"id":2,"name":"All Tracks","val":-2},
                {"id":3,"name":"This Track","val":-3},
                {"id":4,"name":"All Tracks","val":-4}
            ]
        });
        this.scaleSourceSelect = Ext.create('Ext.form.field.ComboBox', {
          fieldLabel : "Y Scale",
          labelAlign : 'right',
          store: self.scales,
          labelWidth:75,
          width:200,
          editable: true,
          queryMode: 'local',
          displayField : 'name',
          valueField : 'val',
          listeners:{
            scope: self,
            'change': function( combo, newValue, oldValue, eOpts) {
              self.scaleSource = newValue;
              self.refresh();
            }

          }
        });
        
      	//Histogram mode
      	var Histogram = (function()
      	{
      		var dataA = new HistogramData();
      		var dataB = new HistogramData();
      		var canvasA = new Sv.painters.HistogramCanvas();
      		var canvasB = new Sv.painters.HistogramCanvas();

      		canvasA.setColor(self.color_above)
      		canvasB.setColor(self.color_below)
      		function parse(data)
      		{
      			// for (var series in data[0])
      			// {
      			// 	addLabel(series);
      			// }
      			dataA.parse(data,true);
      			//dataB.parse(data,false);
      		};

      		canvasB.flipY();

      		canvasA.setContainer(containerA.dom);
      		canvasB.setContainer(containerB.dom);

      		function paint(left, right, bases, pixels)
      		{
      			var subsetA = dataA.subset2canvas(left, right, bases, pixels);
      			//var subsetB = dataB.subset2canvas(left, right, bases, pixels);
      			canvasA.setData(subsetA);
      			canvasB.setData(subsetA);

      			canvasA.paint();
      			canvasB.paint();
      		};
          setAbsMax = function(m)
          {
            canvasA.setAbsMax(m);
          };
      		return {
      			dataA : dataA,
      			dataB : dataB,
      			canvasA : canvasA,
      			canvasB : canvasB,
      			parse : parse,
      			paint : paint,
      			setAbsMax : setAbsMax
      		};
      	})();

      	//Data handling and rendering object
      	var handler = Histogram;

      	var multiplierText = new Ext.Toolbar.TextItem({text:"1x",hidden: !self.Toolbar.isVisible(),});

      	self.Toolbar.insert(4,multiplierText);
      	//self.Toolbar.insert(4,abs_max_text);
        self.Toolbar.insert(4,Ext.create('Ext.toolbar.Separator'));
        self.Toolbar.insert(4,self.scaleSourceSelect);
        self.Toolbar.insert(4,Ext.create('Ext.toolbar.Separator'));
        
        //Peak navigation
      	if(self.peaks){
             self.peak_prev = new Ext.Button({
                 iconCls: 'silk_blue_rewind',
                 tooltip: 'Show previous peak',
                 hidden: !self.Toolbar.isVisible(),
                 handler : function(){
                     self.cur_peak -=1;
                     var loc = AnnoJ.getLocation();
                     loc.position = self.peaks[self.cur_peak].pos;
                     AnnoJ.setLocation(loc);
                     self.fireEvent('browse', loc);
                 }
             });
             self.peak_next = new Ext.Button ({
                 iconCls: 'silk_blue_forward',
                 tooltip: 'Show next peak',
                 hidden: !self.Toolbar.isVisible(),
                 handler : function(){
                     var loc = AnnoJ.getLocation();              
                     if(loc.position == self.peaks[self.cur_peak].pos)
                     {
                         self.cur_peak+=1;
                     }
                     loc.position = self.peaks[self.cur_peak].pos;
                     AnnoJ.setLocation(loc);
                     self.fireEvent('browse', loc);
                 }
             });

             self.toggle_table = new Ext.Button ({
                 iconCls: 'silk_table',
                 tooltip: 'Show peak list',
                 hidden: !self.Toolbar.isVisible(),
                 handler: function(){
                     ps = Ext.data.StoreManager.lookup('peakStore'+self.id);
                     self.win.show();
                     if(ps.getCount()>0) return;
                     ps.load();
                 }
             });

             peakStore = new Ext.data.Store({
                 // store configs
                 model: 'DataPeak',
                 proxy : {
                    type: 'ajax',
                    url: self.data,
                    reader : {
                        type : 'json',
                        id : 'id'
                    },
                    extraParams:{
                         jrws : Ext.JSON.encode({
                             method : 'peak_genes',
                             param  : {
                                 experiment : self.experiment,
                                 bioentry : self.bioentry
                             }
                         }),
                     },
                 },
                 storeId: 'peakStore'+self.id,
                 //autoLoad: true,                         
                 idProperty: 'id',                             
             });

             self.table = new Ext.grid.GridPanel({
                 title: 'Peak locations',
                 iconCls: 'silk_table',
                 store: peakStore,
                 //frame: true,                          
                 columns: [                                  
                     {header: 'Position', width: 100, dataIndex: 'pos'},
                     {header: 'Value', width: 100, dataIndex: 'val'},
                     {header: 'Nearest Gene(s)', width: 175, dataIndex: 'link'}
                 ]
             });

             self.table.on('itemdblclick',function(view, record, htmlItem, index, eventObj, eOpts) {
                 var data = record.get('pos');
                 var loc = AnnoJ.getLocation();  
                 loc.position = data;
                 AnnoJ.setLocation(loc);
                 self.fireEvent('browse', loc);
             })

             self.win = new Ext.Window({
                 x: 150,
                 y: 150,
                 width: 380,
                 height: 450,
                 layout:'fit',
                 border:false,
                 closable:true,
                 closeAction:"hide",
                 items:[
                     self.table
                 ]
             });
             
             self.cur_peak = 0;
             self.Toolbar.insert(4,self.toggle_table); 
             self.Toolbar.insert(4,self.peak_next);
             self.Toolbar.insert(4,self.peak_prev);

             //set the leftmost peak according to given position. If one is not found set it to the last.
             self.set_cur_peak = function(pos){
                 self.cur_peak = 0
                 Ext.each(self.peaks, function(item){
                     if(item.pos >= pos){
                         return false;
                     }
                     self.cur_peak +=1
                 });
                 //Update buttons
                 self.peak_prev.enable();
                 self.peak_next.enable();
                 if (self.cur_peak == 0) {self.peak_prev.disable();}
                 if (self.cur_peak > self.peaks.length-1){self.peak_next.disable();}
             };

             //Send request for Peak data
             Ext.Ajax.request(
             {       
                 url : self.data,
                 method : 'GET',
                 params : {
                     jrws : Ext.encode({
                         method : 'peak_locations',
                         param  : {
                             experiment : self.experiment,
                             bioentry : self.bioentry
                         }
                     })
                 },
                 success  : function(response)
                 {
                     self.peaks = Ext.JSON.decode(response.responseText);
                     self.set_cur_peak(AnnoJ.getLocation().position)
                 },      
             });
      	}

      	//Change the color(s) for this track
      	this.setColor = function(color, above){
      		if(above){
      			self.color_above = color;
      			handler.canvasA.setColor(color);
      			handler.canvasA.refresh();
      		}
      		else{
      			self.color_below = color;
      			handler.canvasB.setColor(color);
      			handler.canvasB.refresh();
      		}
      	};

      	//Create a new menu item for picking a color
        var addColorMenu = function(menuText, above){
            self.contextMenu.ext.add(
             {
                 iconCls: 'silk_palette',
                 text: menuText,
                 menu: {
                         xtype: 'colormenu',
                         handler: function(colorMenu, color){
                             self.setColor(color, above);
                         }//,
                         //colors: self.color_choices
                 }
             });     
        };

      	//Add a seperator for colors
      	self.contextMenu.ext.add('-');
      	//Add the color menus	
      	if (self.single)
      	{	
      		addColorMenu("Color", true)
      	}
      	else
      	{
      		addColorMenu("Color above", true);
      		addColorMenu("Color below", false);
      	}

      	//Zoom policies (dictate which handler to use)
      	var policies = [
      		{ index:0, min:1/100 	, max:10/1    	, bases:1   	, pixels:1  , cache:10000   },
      		{ index:1, min:10/1  	, max:100/1   	, bases:10  	, pixels:1  , cache:100000   },
      		{ index:2, min:100/1 	, max:1000/1  	, bases:100 	, pixels:1  , cache:1000000 },
      		{ index:3, min:1000/1	, max:10000/1		, bases:1000	, pixels:1  , cache:10000000 },
      		{ index:4, min:10000/1, max:100000/1	, bases:10000	, pixels:1  , cache:100000000 }
      	];

      	this.getPolicy = function(view)
      	{
      		var ratio = view.bases / view.pixels;

      		//handler = Histogram;

      		for (var i=0; i<policies.length; i++)
      		{
      			if (ratio >= policies[i].min && ratio < policies[i].max)
      			{			
      				return policies[i];
      			}
      		}
      		return null;
      	};
      	this.rescale = function(f)
      	{
      		
      		var newVal = (f*20)-10 //-10 .. 10
          if(newVal==0) newVal=1; //-10 .. 1 .. 10
          if(newVal<0){
            newVal = 1/(0-newVal) //0.1 .. 1 .. 10
          }
          self.scale = newVal.toFixed(2);
          handler.canvasA.setScaler(newVal);
          handler.canvasB.setScaler(newVal);
          multiplierText.setText(+newVal+" x");
          //var f = Math.pow(f*2, 4);
          // handler.canvasA.setScaler(f);
          // handler.canvasB.setScaler(f);
          // handler.canvasA.refresh();
          // handler.canvasB.refresh();
          // scale_text.setText("Scale: "+f.toFixed(2))
      	};	
      	this.clearCanvas = function()
      	{
      		handler.canvasA.clear();
      		handler.canvasB.clear();
      	};
      	this.paintCanvas = function(l,r,b,p)
      	{
      	  if(self.set_cur_peak){this.set_cur_peak(AnnoJ.getLocation().position);}
      	  handler.setAbsMax(self.getCurrentMax());
      		handler.paint(l,r,b,p);
      	};
      	this.refreshCanvas = function()
      	{
      		handler.canvasA.refresh(true);
      		handler.canvasB.refresh(true);
      	};
      	this.resizeCanvas = function()
      	{
      		handler.canvasA.refresh(true);
      		handler.canvasB.refresh(true);
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
	}
});

