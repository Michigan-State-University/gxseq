/*
The base canvas provides core functionality for managing an HTML canvas that is to be 
inserted into an application. Specific functionality should be provided by extending 
routines.
*/
Ext.define('Sv.painters.BaseCanvas',{
	extend : 'Ext.Component',
  mixes:{
      observable: 'Ext.util.Observable'
  },
  initComponent : function(){
		var self = this;
  	    var container = document.createElement('DIV');
  	    var canvas    = document.createElement('CANVAS');
  	    var brush     = canvas.getContext('2d');
  	    var width     = 0;
  	    var height    = 0;
  	    
  	    //Initialization
  	container.style.position = 'relative';
  	canvas.style.position = 'relative';
  	
  	//Getters
  	this.getContainer = function() { return container; };
  	this.getCanvas    = function() { return canvas;    };
  	this.getBrush     = function() { return brush;     };
  	this.getWidth     = function() { return width;     };
  	this.getHeight    = function() { return height;    };
  	
  	//FIXME: this should consider scroll offset of all ancestors
  	this.getRegion = function()
  	{
  		if (!container || !container.parentNode) return null;
		
  		var pr = Ext.get(container.parentNode).getRegion();
  		var cr = Ext.get(container).getRegion();
  		var ir = cr.intersect(pr);
  		if (!ir) return null;
  		if (ir.top < 0)
  		{
  			var diff = Math.abs(ir.top);
  			ir.top    += diff;
  			ir.bottom += diff;
  			cr.top    += diff;
  			cr.bottom += diff;
  		}
  		if (ir.left < 0)
  		{
  			var diff = Math.abs(ir.left);
  			ir.left  += diff;
  			ir.right += diff;
  			cr.left  += diff;
  			cr.right += diff;
  		}
  		var region = {};
  		region.x1 = ir.left - cr.left;
  		region.y1 = ir.top - cr.top;
  		region.x2 = region.x1 + ir.right - ir.left;
  		region.y2 = region.y1 + ir.bottom - ir.top;
  	
  		return region;
  	};
  	
  	//Setters
  	this.setContainer = function(dom)
  	{
  		if (!dom || !dom.appendChild) return;
  	
  		if (dom.style.position != 'absolute' && dom.style.position != 'relative')
  		{
  			dom.style.position = 'relative';
  		}
  		if (canvas.parentNode)
  		{
  			canvas.parentNode.removeChild(canvas);
  		}
  		dom.appendChild(canvas);
  		container = dom;
  		self.clear();
  	};
  	this.setSize = function(width, height)
  	{ 
  		container.style.width  = parseInt(width)  || container.offsetWidth;
  		container.style.height = parseInt(height) || container.offsetHeight;
  		self.refresh();
  	};
  	
  	//Rendering functions
  	// this.paint = function()
  	// {
  	// 	//Provide implementation in subclasses
  	// };
  	this.refresh = function()
  	{
  		self.clear();
  		self.paint();
  	};
  	this.clear = function()
  	{
  		canvas.innerHTML = '';
  		if(canvas.parentNode==container)		
  		{
  			container.removeChild(canvas);
  		}
  		container.innerHTML = '';
  		container.appendChild(canvas);
  	
  		width = container.offsetWidth;
  		height = container.offsetHeight;
  		canvas.width  = width;
  		canvas.height = height;
  		brush = canvas.getContext('2d');
  		brush.clearRect(0, 0, width, height);
  	};
  	this.paintWedge = function(x,y,w,h,cls)
  	{	
  		s = self.styles.get(cls);
  		brush.fillStyle = s.fill;
  	      brush.beginPath();
  	      brush.moveTo(x+w, y+h); brush.lineTo(x, y+h);
  	      brush.lineTo(x, y); 
  	      brush.closePath();
  	      brush.fill();
  		//brush.fillRect(x, y, w, h);
  	};
  	this.paintWedgeLower = function(x,y,w,h,cls)
  	{
  	
  	
  		s = self.styles.get(cls);
  		brush.fillStyle = s.fill;
  	      brush.beginPath();
  	      // console.log(brush.beginPath());
  	      // brush.moveTo(x-w-3, y+h); brush.lineTo(x, y+h);
  	      // brush.lineTo(x+w+3, y); 
  	      brush.moveTo(x,y+h); brush.lineTo(x,y); brush.lineTo(x+w,y);
  	      brush.closePath();
  	      brush.fill();
  		//brush.fillRect(x, y, w, h);
  	};
  	this.paintBox = function(cls, x, y, w, h)
  	{
  		if (!check(x,y,w,h)) return; 
  		var s = self.styles.get(cls);
  		if (!s) return; 
  	
  	
  		//Set transparency (keep a record of old transparency to restore later)
  		var oldTrans = brush.globalAlpha;
  		brush.globalAlpha = s.opacity;
  	
  		//Draw borders first (if necessary)
  		if (s.border.top.width > 0)
  		{
  			fillBox(s.border.top.color, x, y, w, s.border.top.width);
  			y += s.border.top.width;
  			h -= s.border.top.width;
  		}
  		if (s.border.bottom.width > 0)
  		{
  			fillBox(s.border.bottom.color, x, y + h - s.border.bottom.width, w, s.border.bottom.width);
  			h -= s.border.bottom.width;
  		}
  		if (s.border.left.width > 0)
  		{
  			fillBox(s.border.left.color, x, y, s.border.left.width, h);
  			x += s.border.left.width;
  			w -= s.border.left.width;
  		}
  		if (s.border.right.width > 0)
  		{
  			fillBox(s.border.right.color, x + w - s.border.right.width, y, s.border.right.width, h);
  			w -= s.border.right.width;
  		}
  	
  		//Adjust for padding (if necessary)
  		if (s.padding.top)
  		{
  			x += s.padding.top;
  			h -= s.padding.top;
  		}
  		if (s.padding.bottom)
  		{
  			h -= s.padding.bottom;
  		}
  		if (s.padding.left)
  		{
  			y += s.padding.left;
  			w -= s.padding.left;
  		}
  		if (s.padding.right)
  		{
  			w -= s.padding.right;
  		}
  	
  		//If there is a background color then render the box
  		if (s.fill)
  		{
  			fillBox(s.fill, x, y, w, h);
  		}
  	
  		//If there is a background image then render it
  	
  		if (s.image)
  		{
  			fillImage(s.image, s.background.repeat, x, y, w, h);
  		}
  	
  		//Restore original transparency
  		brush.globalAlpha = oldTrans;
  	};
  	function fillBox(fill,x,y,w,h)
  	{
  		var box = check(x,y,w,h);
  		if (!box) return;
  	
  		brush.fillStyle = fill;
  		brush.fillRect(box.x, box.y, box.w, box.h);
  	};
  	function fillImage(img,repeat,x,y,w,h)
  	{
  		if (!img) return;
  	
      //If the image is not complete then only render it when ready
      //This can cause issues with expected render order.
      
      if (!img.complete)
      {      
       Ext.EventManager.addListener(img, 'load', function()
       {
         fillImage(img,repeat,x,y,w,h);
       });
       return;
      }
       
  		var box = check(x,y,w,h);
  		if (!box) return;
  	
  		//Natural size
  		var imgW = img.width;
  		var imgH = img.height;
  	
  		if (repeat == 'repeat-x')
  		{
  			var numx = Math.floor(box.w / imgW);
  			var diffx = box.w - (numx * imgW);
  	
  			for (var i=0; i<numx; i++)
  			{
  				brush.drawImage(img, box.x + (i*imgW), box.y, imgW, box.h);
  			}
  			if(diffx > 0)
  			{
  				brush.drawImage(img, 0, 0, diffx, imgH, box.x + (i*imgW), box.y, diffx, box.h);
  			}
  		}
  		else if (repeat == 'repeat-y')
  		{
  			var numy = Math.floor(box.h / imgH);
  			var diffy = box.h - (numh * imgH);
  	
  			for (var i=0; i<numy; i++)
  			{
  				brush.drawImage(img, box.x, box.y + (i*imgH), box.w, imgH);
  			}
  			brush.drawImage(img, 0, 0, imgW, diffy, box.x, box.y + (i*imgH), box.w, diffy);
  		}
  		else
  		{
  			brush.drawImage(img, box.x, box.y, box.w, box.h);
  		}
  	};
  	
  	//Set box size parameters so that they the canvas doesn't bother trying to draw off screen
  	function check(x,y,w,h)
  	{
  		var x1 = x;
  		var y1 = y;
  		var x2 = x + w;
  		var y2 = y + h;
  	
  		if (x1 < 0) x1 = 0;
  		if (y1 < 0) y1 = 0;
  	
  		if (x2 >= width)  x2 = width-1;
  		if (y2 >= height) y2 = height-1;
  	
  		if (x1 >= x2 || x2 <= 0 || x1 >= width) return null;
  		if (y1 >= y2 || y2 <= 0 || y1 >= height) return null;
  	
  		return {
  			x : x1,
  			y : y1,
  			w : x2 - x1,
  			h : y2 - y1
  		};
  	};
  	
  	/*
  	 * Object for managing styles associated with a canvas
  	 */
  	this.styles = (function()
  	{
  		var styles = {};
  		var imgCache = {};
  	
  		function set(cls, override)
  		{
  	        // if (!cls || typeof(cls) != 'string'){ console.log("Class isn't a string: returning!"); return; }
  			if (styles[cls] && !override){ console.log("styles[cls] exists and !override: returning"); return; }
  			styles[cls] = build(cls);
  	        // console.log(styles[cls]);
  		};
  		function get(cls)
  		{
  			if (!cls || typeof(cls) != 'string') return null;
  			if (!styles[cls]) set(cls);
  			return styles[cls] || null;
  		};
  		function remove(cls)
  		{
  			if (!cls || typeof(cls) != 'string') return;
  			if (styles[cls]) delete styles[cls];
  		};
  		function clear()
  		{
  			delete styles;
  			styles = {};
  		};
  	
  		//Compile a CSS style for use with the canvas
  		function build(cls)
  		{
  	        if (!cls || typeof(cls) != 'string'){ cls = cls[0]; console.log("cls was an array, setting to: "+cls) }
  			if (!container || !container.appendChild) container = document.body;
  	
  			var div = Ext.get(document.createElement('DIV'));
  			div.addCls(cls);
  			div.appendTo(container);
  			var css = {
  				opacity : div.getStyle('opacity'),
  				image   : null,
  				fill : div.getColor('background-color'),
  				line : div.getColor('color') || 'black',
  				w : div.getWidth(),
  				h : div.getHeight(),
  				x : div.getTop(),
  				y : div.getLeft(),
  				background : {
  					image : div.getStyle('background-image'),
  					color : div.getColor('background-color'),
  					repeat : div.getStyle('background-repeat'),
  					position : div.getStyle('background-position') //there is a bug in Mozilla that prevents this working
  				},
  				margin : {
  					top   : div.getMargin('t'),
  					bottom : div.getMargin('b'),
  					left   : div.getMargin('l'),
  					right  : div.getMargin('r')
  				},
  				border : {
  					top : {
  						width : div.getBorderWidth('t'),
  						color : div.getColor('border-top-color')
  					},
  					bottom : {
  						width : div.getBorderWidth('b'),
  						color : div.getColor('border-bottom-color')
  					},
  					left : {
  						width : div.getBorderWidth('l'),
  						color : div.getColor('border-left-color')
  					},
  					right : {
  						width : div.getBorderWidth('r'),
  						color : div.getColor('border-right-color')
  					}
  				},
  				padding : {
  					top    : div.getPadding('t'),
  					bottom : div.getPadding('b'),
  					left   : div.getPadding('l'),
  					right  : div.getPadding('r')
  				}
  			};
  			//Deal with a background image
  			if (css.background.image.substr(0,4) == 'url(')
  			{
  	    			var src = ''
  			  if(css.background.image.substr(4,1) == '"'){
  			    src = css.background.image.substr(5, css.background.image.length-7);
  	
  			  }
  			  else {
  	            src = css.background.image.substr(4, css.background.image.length-5);
  	          }
  				var img = new Image();
  				img.src = src
  				css.image = img;
  			}
  			else
  			{
  				css.image = null;
  			}
  			div.remove();
  			return css;
  		};
  	
  		return {
  			set       : set,
  			get       : get,
  			remove    : remove,
  			clear     : clear,
  			build     : build
  		};
  	})();
  	
  },
})
