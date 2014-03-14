Ext.define("Sv.tracks.RatioTrack",{
  extend:"Sv.tracks.BrowserTrack",
  single   : false,
  clsAbove : 'AJ_above',
  color_above: 'A00608',
  color_below: '003300',
  hasPeaks: false,
  initComponent : function(){
    this.callParent(arguments);
    var self = this;
    this.viewMax = 1;
    this.allViewMax = 1;
    this.scaleSource = -2;
    //Initialize the DOM
    var container = new Ext.Element(document.createElement('DIV'));
    container.addCls(self.clsAbove);
    container.setStyle('position', 'relative');
    container.setStyle('width', '100%');
    container.setStyle('height', '100%');
    container.appendTo(self.Canvas.ext);
    
    
    this.getViewMax = function(location){
      var edges = self.DataManager.getEdges()
      var newMax = handler.data.getMaxY(edges.g1,edges.g2).toFixed(2)
      self.setViewMax(newMax);
      return newMax;
    }
    //called by main app to update view max
    this.setViewMax = function(newMax){
      self.viewMax = newMax;
      self.scales.getById(1).set('name','This '+self.type+' ('+newMax+')');
      if(self.scaleSource==-1){
        self.scaleSourceSelect.setRawValue('This '+self.type+' ('+newMax+')');
      }
    }
    this.setAllViewMax = function(newMax){
      self.allViewMax = newMax;
      self.scales.getById(2).set('name','All '+self.type+' ('+newMax+')');
      if(self.scaleSource==-2){
        self.scaleSourceSelect.setRawValue('All '+self.type+' ('+newMax+')');
      }
    }
    //get the max that we will use to draw
    this.getCurrentMax=function(left,right){
      switch(self.scaleSource)
      {
      case -1:
        newScale = self.viewMax;
        break;
      case -2:
        newScale = self.allViewMax;
        break;
      default:
        newScale = self.scaleSource;
      }
      return newScale;
    }
    
    // Setup the scale select list
    this.scales = Ext.create('Ext.data.Store', {
        fields: ['id', 'name', 'val'],
        data : [
            {"id":1,"name":"This "+self.type,"val":-1},
            {"id":2,"name":"All "+self.type,"val":-2}
        ]
    });
    this.scaleSourceSelect = Ext.create('Ext.form.field.ComboBox', {
      fieldLabel : "Y Scale",
      labelAlign : 'right',
      store: self.scales,
      labelWidth:75,
      width:300,
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
    
    self.Toolbar.insert(4,Ext.create('Ext.toolbar.Separator'));
    self.Toolbar.insert(4,self.scaleSourceSelect);
    
    //Histogram mode
    var Ratio = (function()
    {
      var rData = new RatioData();
      var canvas = new Sv.painters.RatioCanvas();

      function parse(data)
      {
        rData.parse(data,true);
      };

      canvas.setContainer(container.dom);

      function paint(left, right, bases, pixels)
      {
        var subset = rData.subset2canvas(left, right, bases, pixels);
        canvas.setMad(rData.getMad());
        canvas.setMedian(rData.getMedian());
        canvas.setData(subset);
        canvas.paint();
      };
      setMax = function(m)
      {
        canvas.setAbsMax(m);
      };
      return {
        data : rData,
        canvas : canvas,
        parse : parse,
        paint : paint,
        setMax : setMax
      };
    })();

    //Data handling and rendering object
    var handler = Ratio;

    //Zoom policies (dictate which handler to use)
    var policies = [
    { index:0, min:1/100  , max:2/1     , bases:1     , pixels:1  , cache:10000 },
    { index:1, min:2/1    , max:10/1      , bases:1     , pixels:1  , cache:10000 },
    { index:2, min:10/1   , max:100/1     , bases:10    , pixels:1  , cache:100000   },
    { index:3, min:100/1  , max:1000/1    , bases:100   , pixels:1  , cache:1000000 },
    { index:4, min:1000/1 , max:10000/1   , bases:1000  , pixels:1  , cache:10000000 },
    { index:5, min:10000/1, max:100000/1  , bases:10000 , pixels:1  , cache:100000000 }
    ];

    this.getPolicy = function(view)
    {
      var ratio = view.bases / view.pixels;
      //handler = Histogram;
      for (var i=0; i<policies.length; i++)
      {
        if (ratio >= policies[i].min && ratio < policies[i].max){ return policies[i]; }
      }
      return null;
    };
    this.rescale = function(f)
    {    };  
    this.clearCanvas = function()
    {
      handler.canvas.clear();
    };
    this.paintCanvas = function(l,r,b,p)
    {
      handler.setMax(self.getCurrentMax());
      handler.paint(l,r,b,p);
    };
    this.refreshCanvas = function()
    {
      handler.canvas.refresh(true);
    };
    this.resizeCanvas = function()
    {
      handler.canvas.refresh(true);
    };
    this.clearData = function()
    {
      handler.data.clear();
    };
    this.pruneData = function(a,b)
    {
      handler.data.prune(a,b);
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
      scale : track.scale
    }
  }
});

