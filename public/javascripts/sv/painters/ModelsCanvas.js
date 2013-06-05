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
    // Build Image Map for click event    
    //Add an empty map 
    var modelMap = document.createElement('MAP');
    modelMap.setAttribute("id",""+container.id+"map");
    modelMap.setAttribute("name",""+container.id+"map");
    container.appendChild(modelMap);
    //Add an array to hold the area tags
    var mapAreas = [];
    //Add the img tag
    var mapImage = document.createElement('IMG');
    mapImage.style.width = width+"px";
    mapImage.style.height = height+"px";
    mapImage.style.left = "0px";
    mapImage.style.top = "0px";
    mapImage.style.position = "absolute";
    //An image without a src might have a border rendered by the browser. Use a 1x1 empty image instead
    mapImage.src = 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='
    //tie the img to the map
    mapImage.setAttribute("usemap","#"+container.id+"map");
    container.appendChild(mapImage);
    //Setup font height and get width -- rough estimate
    var font_height = (h) / ((pixelBaseRatio/55)+1)
    var fontLetterWidth = font_height / 2
    //Levelize the models and get the max visible level (used for a shortcut later)
    var maxLevel = Math.ceil(region.y2 / (h + self.boxSpace));
    var max = this.levelize(self.data,maxLevel);
    //Work on each gene model
    Ext.each(self.data, function(model)
    {
      //Lookup class and check active flag
      if (!self.groups.active(model.cls)) return;
      if (model.level > maxLevel) return;
      //Setup coordinates
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
      // ----Image Map Areas--- //
      if(w>2 && self.selectable)
      {
        mapAreas.push("<area shape='rect' coords='"+x+","+y+","+(x+w)+","+(y+h)+"' id=model_"+model.oid+" data-id="+model.oid+" href='#' alt='"+model.locus_tag+" "+model.gene+"' title='"+model.locus_tag+" "+model.gene+"'>");
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
      // ---Painting the Label--- //
      // setup the label
      if(model.gene==''){
        label=model.locus_tag;
      }
      else
      {
        label=model.gene;
      };
      var label_width = (fontLetterWidth*label.length);
      // Test boundaries
      var Offset = x+1;
      if(Offset <=1){
        //left side of screen
        label = "("+label+")"
        Offset = 1;
      }else if(Offset >= (width-1)){
        //right side of screen
        Offset = (width-1);
      }
      //test right side of model - add 4 letterwidths for parentheses and slight end padding
      //This will 'pull' the label off screen to the left
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
    // Click handler
    this.clickModel = function(event, srcEl, obj){
      var el = Ext.get(srcEl);
      self.fireEvent('modelSelected', el.dom.getAttribute('data-id'));
    }
    //Append all the map areas we created
    modelMap.innerHTML+=mapAreas.join("\n");
    //setup the click event
    for(i=0;i<modelMap.children.length;i++){
      Ext.get(modelMap.children[i]).addListener('mouseup', self.clickModel)
    }
  }
});
