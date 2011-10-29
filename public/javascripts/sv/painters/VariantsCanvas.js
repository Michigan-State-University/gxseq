/*
 * Class for displaying sequence variance as non-overlapping boxes. Shows sequence when zoomed in close
 */
Ext.define('Sv.painters.VariantsCanvas',{
    extend: 'Sv.painters.BoxesCanvas',
		boxHeight : 8,
		boxHeightMax : 24,
		boxHeightMin : 1,
		boxBlingLimit : 5,
		boxSpace : 1,
		initComponent : function(){
			this.callParent(arguments);
			var self = this;
			var data = [];

			self.addEvents({
				'itemSelected' : true
			});

			//Set the data for this histogram from an array of points
			this.setData = function(items)
			{
				if (!(items instanceof Array)) return;

				Ext.each(items, function(item)
				{
					self.groups.add(item.cls);
				});
				data = items;
			};

			//Draw points using a specified rendering class
			this.paint = function()
			{
				this.clear();

				if (!data || data.length == 0) return;
				var container = this.getContainer();
				var canvas = this.getCanvas();
				var region = this.getRegion();
				var width = this.getWidth();
				var height = this.getHeight();
				var brush = this.getBrush();
				var scaler = this.getScaler();
				var x = 0;
				var y = 0;
				var w = 0;
				var h = Math.round(self.boxHeight * scaler);
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

				//Levelize the data and get the max visible level (used for a shortcut later)
				var max = this.levelize(data);
				var maxLevel = Math.ceil(region.y2 / (h + self.boxSpace));
				var newDivs = [];
				Ext.each(data, function(variant)
				{
					self.groups.add(variant.cls);
					if (!self.groups.active(variant.cls)) return;
					if (variant.level > maxLevel) return;

					w = variant.w;
					x = variant.x;
					y = height-(variant.level * (h + self.boxSpace)) -h;
					if (x + w < region.x1 || x > region.x2) return;
					if (y + h < region.y1 || y > region.y2) return;
		            self.paintBox(variant.cls, x, y, w, h);
		            if(w>2)
					{
		                newDivs.push("<div id=seq_variant_"+variant.id+" data-id="+variant.id+" style='width: "+w+"px; height: "+h+"px; left: "+x+"px; top: "+y+"px; cursor: pointer; position: absolute;'></div>");
		            }
		            if (variant.seq)
		            {
		                letterize(brush, variant.seq, x, y, w, h, container);
		            }
				});
				//Append all the html DIVs we created
		        containerDiv.innerHTML+=newDivs.join("\n");
		        //setup the click event
		        for(i=0;i<containerDiv.children.length;i++)
		           Ext.get(containerDiv.children[i]).addListener('mouseup', selectItem);
				//return the new height we want for rendering
				return((h+self.boxSpace)*max);
			};

		    function letterize(brush, sequence, x, y, w, h, container)
		    {
		        var clean = "";
		        var length = sequence.length;
		        var letterW = AnnoJ.bases2pixels(1);
		        var half = length/2;
		        var readLength = half * letterW;
		        if(letterW > 1 || h < self.boxBlingLimit)
		        {
		            for (var i=0; i<length; i++)
		            {
		                var letter = sequence.charAt(i);

		                switch (letter)
		                {
		                    case 'A': letter = 'A_trans';break;
		                    case 'T': letter = 'T_trans';break;
		                    case 'C': letter = 'C_trans';break;
		                    case 'G': letter = 'G_trans';break;
		                    case 'N': letter = 'N_trans';break;
		                    case 'a': letter = 'A_trans'; break;
		                    case 't': letter = 'T_trans'; break;
		                    case 'c': letter = 'C_trans'; break;
		                    case 'g': letter = 'G_trans'; break;
		                    default : letter = 'N_trans';
		                }
		                clean += letter;

		                var letterX = x + (i * letterW) + (i >= half ? w-2*readLength : 0);

		                self.paintBox(letter, letterX, y, letterW, h);

		            };
		        }
		    };

			function selectItem(event, srcEl, obj)
			{
				var el = Ext.get(srcEl);
				self.fireEvent('itemSelected', el.dom.getAttribute('data-id'));
			};
		}
		
});

