/*
 * Class for displaying gene models of other data with one level of nesting
 */
Ext.define('Sv.painters.GenericFeatureCanvas', {
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
	forward_arrow :"forward_arrow",
	reverse_arrow : "reverse_arrow",
	initComponent : function(){
		this.callParent(arguments);
		var self = this;
		var data = [];
		var ratio = 1;
		self.addEvents({
			'modelSelected' : true
		});

		if (self.strand == '+' && !self.flippedY) self.flipY();
		if (self.strand == '-' && self.flippedY) self.flipY();

		//Setters
		this.setBoxHeight = function(h)
		{
			var h = parseInt(h) || 0;

			if (h < self.boxHeightMin) h = self.boxHeightMin;
			if (h > self.boxHeightMax) h = self.boxHeightMax;

			self.boxHeight = h;
		};
		this.setBoxSpace = function(s)
		{
			var s = parseInt(s) || 0;
			self.boxSpace = s < 0 ? 0 : s;
		};
		this.setLabels = function(state)
		{
			self.labels = state ? true : false;
		};
		this.setArrows = function(state)
		{
			self.arrows = state ? true : false;
		};
		this.setStrand = function(s)
		{
			self.strand = (s == '+') ? '+' : '-';
		};
		this.setData = function(models)
		{
			if (!(models instanceof Array)) return;
			data = [];

			Ext.each(models, function(model)
			{
				model.x1 = model.x;
				model.x2 = model.x + model.w;
	      // Ext.each(model.cls, function(cls){
				self.groups.add(model.cls);
	      // });
	      // self.groups.add(model.cls);      
			});

			data = models;
		};

		this.getArrowWidth = function()
		{
			return self.arrow_width * this.getScaler();
		}
		this.getPixelBaseRatio = function()
		{
			return ratio;
		};
		this.setPixelBaseRatio = function(i)
		{
			ratio = i;
		};
		var labels_div = document.createElement('DIV');

		//Draw points using a specified rendering class
		this.paint = function()
		{
			this.clear();

			if (!data || data.length == 0) return;

			var container = this.getContainer();
			var canvas = this.getCanvas();
			var region = this.getRegion();
			if(!region) return;
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

			//Setup font height and get width
			var font_height = (h) / ((pixelBaseRatio/55)+1)
			//This is just an estimate.
			//var fontLetterWidth = 7.2 * scaler;
			var fontLetterWidth = font_height / 2

			//Levelize the reads and get the max visible level (used for a shortcut later)
			var maxLevel = Math.ceil(region.y2 / (h + self.boxSpace));
			var max = this.levelize(data,maxLevel);
			
			var html = '';
			var id = '';

			//JS will be too slow if too many divs are being drawn
			Ext.each(data, function(model)
			{
				if (!self.groups.active(model.cls)) return;
				if (model.level > maxLevel) return;
				id = model.id
				//Draw the model and its sub-components
				var w = model.w;
				var x = model.x;
				var y = (model.level*h)+(model.level*font_height)+5;
				var arrow_width = self.getArrowWidth();
				labelY = y+h;
				if (flippedX) x = width - x - w;
				if (flippedY){
					y = (height - y)-h;
					labelY = (height - labelY)-(font_height+1);
				}					
				if (x + w < region.x1 || x > region.x2) return;
				if (y + h < region.y1 || y > region.y2) return;
				model_width=w
				if(w>2 && self.selectable)
				{
					// ----Creating a Canvas Wrapper Div--- //
					var div1 = document.createElement('DIV');
					div1.style.width = w+"px";
					div1.style.height = h+"px";
					div1.style.marginLeft = x+"px";
					div1.style.top = y+"px";
					div1.style.cursor = "pointer";
					div1.style.position = "absolute";
					div1.setAttribute('id',"model_"+model.oid);
					div1.setAttribute('data-id',model.oid);
					container.appendChild(div1);
					var model_width = div1.offsetWidth;
					d = Ext.get(div1)
					d.addListener('mouseup', clickGenericFeature);
					// -------------------------------------- //
				}
				self.paintBox(model.cls, x, y, w, h);
				var max_x = (x+w);
				Ext.each(model.children, function(child)
				{
						if(child.x2>max_x){max_x = child.x2;} //store the maximum pixel of the children for the arrow image
	  				self.paintBox(child.cls, child.x, y,(child.x2-child.x), h);
				});

				//Draw the arrow point
				if(self.arrows && self.arrow_width)
				{
					var aw = self.arrow_width;
					if(self.strand =='+'){
						self.paintBox(self.forward_arrow,max_x-aw,y,aw,h);
					}else{
						self.paintBox(self.reverse_arrow,x,y,aw,h);
					}
				}

	      // if(model.gene==''){
	      //  label=model.locus_tag;
	      // }
	      // else
	      // {
	        label="";
	      // };
				var label_width = (fontLetterWidth*label.length);

				//set to the left of model
	      var Offset = x+1;

				//test the left side of screen
				if(Offset <=1){
				  Offset = 1;
	       // label = "("+label+")"
	       label = ""
				}
				//test the right side of the screen
				else if(Offset >= (width-1)){
					Offset = (width-1);
				}

				topOffset = Offset;		
				bottomOffset = Offset

				//test right side of model
				if(bottomOffset >= (x+w)-(label_width)){
					bottomOffset = (x+w)-(label_width);
				}
				//Draw the label
	  		if (h >= self.boxBlingLimit && label_width < model_width && font_height > 5)
	  		{
					labelY+=font_height
					brush.font='italic 400 '+font_height+'px arial, sans-serif'
					brush.fillStyle='#333333'
					if(self.strand =='+'){
						brush.fillText(label,bottomOffset, labelY)
					}
					else{
						brush.fillText(label,topOffset, labelY)
					}
				}
			});		
		};

		function clickGenericFeature(event, srcEl, obj)
		{
			var el = Ext.get(srcEl);
			self.fireEvent('modelSelected', el.dom.getAttribute('data-id'));
		};
		
	}
});