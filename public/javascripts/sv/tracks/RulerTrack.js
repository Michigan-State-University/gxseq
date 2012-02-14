Ext.define('Sv.tracks.RulerTrack',{
  extend : 'Ext.Component',
  curView : {},  
  mixes:{
      observable: 'Ext.util.Observable'
  },  
  height: 30,
  initComponent: function(){
    var me = this;
    me.callParent(arguments);
    
    me.canvas = document.createElement('CANVAS');
    me.brush = me.canvas.getContext('2d');
    
    me.body = Ext.create('Ext.panel.Panel',{
      height: '30px',
      renderTo: document.body,
      layout:'fit',
      cls : 'AJ_track',
      bodyStyle:{
        'background-color': 'rgba(255,255,255,0)',
        border : 'none'
      },
      contentEl : me.canvas
    });    
  },
  drawRuler : function(){
    var me = this;
    if(!me.body.rendered){return};
    
    me.body.setWidth( me.body.getEl().parent().getWidth());
    
    var brush = me.brush;
    var bases = me.curView.bases;
    var pixels = me.curView.pixels;
    var pos = me.curView.position;
    var width = me.getWidth();
    var height = me.getHeight();    
    
    me.canvas.width = width;
    me.canvas.height = height;
    
    var fontHeight = 8;
    var tickheight = 6;
    var condense = false;
    var label = '';
    
    var baseStart = pos-Math.round(AnnoJ.pixels2bases(width)/2);
    var offset = AnnoJ.bases2pixels(baseStart);  
    var zoom = 1;
    if(bases > 1){
      zoom = Math.pow(10, Math.floor(Math.log(bases) / Math.LN10)) * 10;
      condense = false;
    }
    else if(pixels >= 10){
      zoom = 0.1;
    }
    var majorFactor = zoom*100;
    var minorFactor = zoom*10;
    
    var majorTick = Math.floor(baseStart / majorFactor);
    var minorTick = Math.floor(baseStart / minorFactor);
    
    brush.fillStyle="rgb(80,60,40)";
    brush.fillRect(0,(height/2)-1,width, 2);
    brush.textAlign = 'center';
    
    for(var x=0;x<width;x++){
      var seqPos = AnnoJ.pixels2bases(x+offset);
      //draw the major tick and the label
      if(Math.floor(seqPos / majorFactor) > majorTick){
        majorTick = Math.floor(seqPos / majorFactor);
        minorTick = Math.floor(seqPos / minorFactor);
        if(condense){label = AnnoJ.numberToSize(seqPos,2);}
        else{label = seqPos;}
        // NOTE x-1: track is offset 1 pixel from the trackManager coordinates
        brush.fillText(label,x-1,(height/2)-4);
        brush.fillRect(x-1,(height/2),1,tickheight*2);
      }
      //draw the minor tick
      else if(Math.floor(seqPos / minorFactor) > minorTick){
        minorTick = Math.floor(seqPos / minorFactor);
        brush.fillRect(x-1,(height/2),1,tickheight);
      }
    }
  },
  //The Following functions implement the Minimum Required API for a track
  setLocation : function(view){
    var me = this;
    me.curView = view;
    me.drawRuler();
  },
  moveCanvas : function(offset){
    var me = this;    
    me.body.setPosition(offset,0);
  },
  doLayout : function(){
    // No special layout on resize/refresh
  },
  insertFrameBefore : function(dom_item){
    var me = this;
    me.body.getEl().insertBefore(dom_item);
  },
  appendFrameTo : function(dom_item){
    var me = this;
    me.body.getEl().appendTo(dom_item);
  },
  open : function(){
    var me = this;
    me.setLocation(AnnoJ.getLocation());
  },
  close : function(){
    // the ruler cannot be closed
  },
  getX    : function()        {return this.body.getPosition()[0];},
  getY    : function()        {return this.body.getPosition()[1];},
  getWidth      : function()  {return this.body.getWidth();},
  getHeight     : function()  {return this.body.getHeight();},
  getMinHeight  : function()  {return this.body.getHeight();},
  getMaxHeight  : function()  {return this.body.getHeight();}  
});