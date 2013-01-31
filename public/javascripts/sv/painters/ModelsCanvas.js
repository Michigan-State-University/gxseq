//Class for displaying gene models with UTR, Introns and CDS
Ext.define('Sv.painters.ModelsCanvas',{
  extend: 'Sv.painters.BoxesCanvas',
  boxHeight : 10,
  boxHeightMax : 24,
  boxHeightMin : 1,
  boxBlingLimit : 5,
  boxSpace : 12,
  labels : true,
  arrows : true,
  arrow_width : 10,
  strand : '+',
  selectable : true,
  checkBoundaries : true,
  forward_arrow :"forward_arrow",
  reverse_arrow : "reverse_arrow",
  ratio : 1,
  scaler : 1,
  data : [],
  initComponent : function(){
    this.callParent(arguments);
    var self = this;
    self.addEvents({
      'modelSelected' : true
    });
    if (self.strand == '+' && !self.flippedY) self.flipY();
    if (self.strand == '-' && self.flippedY) self.flipY();
  },
  //Setters
  setBoxHeight : function(h)
  {
    var h = parseInt(h) || 0;

    if (h < this.boxHeightMin) h = this.boxHeightMin;
    if (h > this.boxHeightMax) h = this.boxHeightMax;

    this.boxHeight = h;
  },
  setBoxSpace : function(s)
  {
    var s = parseInt(s) || 0;
    this.boxSpace = s < 0 ? 0 : s;
  },
  setCheckBoundaries : function(bool)
  {
    this.checkBoundaries = bool;
  },
  setLabels : function(state)
  {
    this.labels = state ? true : false;
  },
  setArrows : function(state)
  {
    this.arrows = state ? true : false;
  },
  setStrand : function(s)
  {
    this.strand = (s == '+') ? '+' : '-';
  },
  setData : function(models)
  {
    var self = this;
    if (!(models instanceof Array)) return;
    Ext.each(models, function(model)
    {
      //model.x1 = model.x;
      //model.x2 = model.x + model.w;
      self.groups.add(model.cls);
    });
    self.data = models;
  },
  getArrowWidth : function()
  {
    return this.arrow_width * this.getScaler();
  },
  getPixelBaseRatio : function()
  {
    return this.ratio;
  },
  setPixelBaseRatio : function(i)
  {
    this.ratio = i;
  },
  paint : function(){
    var self = this;
    self.clear();

    if (!self.data || self.data.length == 0) return;		  	  
    var container = this.getContainer();
    if(!container) return
    var region = this.getRegion();
    if(!region) return;
    var canvas = this.getCanvas();
    var width = this.getWidth();
    var height = this.getHeight();
    var brush = this.getBrush();
    var scaler = this.getScaler();
    var flippedX = this.isFlippedX();
    var flippedY = this.isFlippedY();
    var pixelBaseRatio=this.getPixelBaseRatio();
    var  labelY;
    var h = scaler * self.boxHeight;
    if (h < self.boxHeightMin) h = self.boxHeightMin;
    if (h > self.boxHeightMax) h = self.boxHeightMax;

    //Div we can use to alter innerHTML
    var containerDiv = document.createElement('DIV');
    containerDiv.style.width = width+"px";
    containerDiv.style.height = height+"px";
    containerDiv.style.left = "0px";
    containerDiv.style.top = "0px";
    containerDiv.style.position = "absolute";
    container.appendChild(containerDiv);

    //Setup font height and get width -- rough estimate
    var font_height = (h) / ((pixelBaseRatio/55)+1)
    var fontLetterWidth = font_height / 2

    //Levelize the reads and get the max visible level (used for a shortcut later)
    var maxLevel = Math.ceil(region.y2 / (h + self.boxSpace));
    var max = this.levelize(self.data,maxLevel);
    
    var html = '';
    var id = '';

    //JS will be too slow if too many divs are being drawn - use an array and innerHTML instead
    var newDivs = [];
    Ext.each(self.data, function(model)
    {
      if (!self.groups.active(model.cls)) return;
      if (model.level > maxLevel) return;
      id = model.id;
      //Draw the model and its sub-components
      var w = model.w;
      var x = model.x;
      var y = (model.level*h)+(model.level*font_height)+5;
      labelY = y+h;
      if (flippedX) x = width - x - w;
      if (flippedY){
        y = (height - y)-h;
        labelY = (height - labelY)-(font_height+1);
      }
      if(self.checkBoundaries == true){
        if (x + w < region.x1 || x > region.x2) return;
        if (y + h < region.y1 || y > region.y2) return;
      }

      var model_width=w;

      // ----Creating a Canvas Wrapper Div--- //
      if(w>2 && self.selectable)
      {
        newDivs.push("<div id=model_"+model.oid+" data-id="+model.oid+" style='width: "+w+"px; height: "+h+"px; left: "+x+"px; top: "+y+"px; cursor: pointer; position: absolute;'></div>");
      }

      // ----Painting the model and any children--- //
      self.paintBox(model.cls, x, y, w, h);
      var max_x = (x+w);
      // Loop over each child level (levels provided by data source)
      Ext.each(model.children, function(level)
      {
        //Then paint items in each level
        Ext.each(level, function(child){
          //store the maximum pixel of the children for the arrow image
          if(child.x2>max_x){max_x = child.x2;}
          self.paintBox(child.cls,child.x,y,(child.x2-child.x),h);
        });
      });

      //Draw the arrow point
      if(self.arrows && self.arrow_width)
      {
        var aw = self.arrow_width;
        if(self.strand =='+'){
          self.paintBox(self.forward_arrow,max_x-aw,y-1,aw,h+2);
        }else{
          self.paintBox(self.reverse_arrow,x,y-1,aw,h+2);
        }
      }

      //setup the label
      if(model.gene==''){
        label=model.locus_tag;
      }
      else
      {
        label=model.gene;
      };
      var label_width = (fontLetterWidth*label.length);

      //set to the left of model
      var Offset = x+1;

      //test the left side of screen
      if(Offset <=1){
        label = "("+label+")"
        Offset = 1;
        
      }
      //test the right side of the screen
      else if(Offset >= (width-1)){
        Offset = (width-1);
      }

      //test right side of model - add 4 letterwidths for parentheses and slight end padding
      var max_right_offset = (x+w)-(label_width+(4*fontLetterWidth))
      if(Offset >= max_right_offset){
        Offset = (max_right_offset);
      }
      //Draw the label
      if (h >= self.boxBlingLimit && label_width < model_width && font_height > 5)
      {
        labelY+=font_height
        brush.font='italic 400 '+font_height+'px arial, sans-serif'
        brush.fillStyle='#333333'
        // if(self.config.strand =='+'){
        //   brush.fillText(label,bottomOffset, labelY)
        // }
        // else{
          brush.fillText(label,Offset, labelY)
        //}
      }
    });

    //Append all the html DIVs we created
    containerDiv.innerHTML+=newDivs.join("\n");

    //setup the click event
    for(i=0;i<containerDiv.children.length;i++)
    Ext.get(containerDiv.children[i]).addListener('mouseup', self.clickModel);

    this.clickModel = function(event, srcEl, obj){
      var el = Ext.get(srcEl);
      self.fireEvent('modelSelected', el.dom.getAttribute('data-id'));
    }
  }
});


//var labels_div = document.createElement('DIV');