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

      	this.absMax =0;
      	this.peaks=[];

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
      	var handler = Histogram;

      	//Get the absolute max for this track
      	Ext.Ajax.request(
      	{		
      		url : self.data,
      		method : 'GET',
      		params : {
      			jrws : Ext.encode({
      				method : 'abs_max',
      				param  : {
      					experiment : self.experiment,
      					bioentry : self.bioentry
      				}
      			})
      		},	
      		success  : function(response)
      		{
      			self.absMax = parseFloat(response.responseText).toFixed(2);
      			handler.canvasA.setAbsMax(self.absMax);
      			handler.canvasB.setAbsMax(self.absMax);
      			self.refreshCanvas();
      			update_max_text();
      		},		
      	});

      	//add Max and Scale info to the toolbar
      	var scale_text = new Ext.Toolbar.TextItem({text:"Scale: 1.00",hidden: !self.Toolbar.isVisible(),});
      	var abs_max_text = new Ext.Toolbar.TextItem({text:"",hidden: !self.Toolbar.isVisible(),});

      	function update_max_text(){
      		if(self.single){
      			abs_max_text.setText("Maximum: "+self.absMax);	
      		}else{
      			abs_max_text.setText("Absolute Maximum: "+self.absMax);
      		}
      	}

      	self.Toolbar.insert(4,scale_text);
      	self.Toolbar.insert(4,abs_max_text);

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
        addColorMenu = function(menuText, above){
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

      		handler = Histogram;

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
      		var f = Math.pow(f*2, 4);
      		handler.canvasA.setScaler(f);
      		handler.canvasB.setScaler(f);
      		handler.canvasA.refresh();
      		handler.canvasB.refresh();
      		scale_text.setText("Scale: "+f.toFixed(2))
      	};	
      	this.clearCanvas = function()
      	{
      		handler.canvasA.clear();
      		handler.canvasB.clear();
      	};
      	this.paintCanvas = function(l,r,b,p)
      	{
      	  if(self.set_cur_peak){this.set_cur_peak(AnnoJ.getLocation().position);}
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

