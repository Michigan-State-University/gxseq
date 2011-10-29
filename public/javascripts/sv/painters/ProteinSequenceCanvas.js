/*
 * Class for a DNA sequence canvas
 */
Ext.define('Sv.painters.ProteinSequenceCanvas',{
    extend: 'Sv.painters.BoxesCanvas',
		boxHeight : 20,
		boxHeightMax : 24,
		boxHeightMin : 1,
		boxBlingLimit : 6,
		boxSpace : 1,
		pairedEnd : false,
		initComponent : function(){
			this.callParent(arguments);
			var self = this;
			var data = [];
			
			this.setData = function(sequence)
			{
				if (!(sequence instanceof Array) || sequence.length == 0) return;
				data = [];

				Ext.each(sequence, function(seq)
				{
				  seq.x1 = seq.x;
				  seq.x2 = seq.x + seq.w;
		      // Ext.each(model.cls, function(cls){
				    self.groups.add(seq.cls);
		        // });
		        // self.groups.add(model.cls); 
				});
				data = sequence;
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
					var flippedX = this.isFlippedX();
					var flippedY = this.isFlippedY();

					var x = 0;
					var y = 0;
					var w = 0;
					var e = 0;
					var h = Math.round(self.config.boxHeight * scaler);

					if (h < self.config.boxHeightMin) h = self.config.boxHeightMin;
					if (h > self.config.boxHeightMax) h = self.config.boxHeightMax;

					Ext.each(data, function(read)
					{
						var groups = self.groups.getList();
						self.groups.add(read.cls);
						if (!self.groups.active(read.cls)) return;
			      var letterW = AnnoJ.bases2pixels(1);
			      var baseW = AnnoJ.pixels2bases(1);
						w = read.w;
						x = read.x;
			      left = (0-(x/letterW));
			      if (left < 0) left = 0;

			      y = (height/2) - (h/2);

						if (x + w < region.x1 || x > region.x2) {
						  	return;
						}
			      fontSize=Math.round((w*3)/read.sequence.length)-1;
			      brush.font= fontSize+'px monospace arial, sans-serif'
			      brush.fillText(read.sequence, x, y, w);

						// ----Creating a Canvas Wrapper Div--- //
						var div1 = document.createElement('DIV');
						div1.style.width = w+"px";
						div1.style.height = fontSize+"px";
						div1.style.marginLeft = x+"px";
						div1.style.top = (y - fontSize)+"px";
						div1.style.cursor = "pointer";
						div1.style.position = "absolute";
						div1.setAttribute('id',"protein_"+read.oid);
						div1.setAttribute('data-id',read.oid);
						div1.setAttribute('seq-id',read.sequence);
			      div1.setAttribute('locus_tag',read.locus_tag);
						container.appendChild(div1);
						var model_width = div1.offsetWidth;
						d = Ext.get(div1)
			      d.addListener('mouseup', clickModel);
						// -------------------------------------- //

					});
				};
			

			function clickModel(event, srcEl, obj)
			{
				var el = Ext.get(srcEl);
				var cleanedSeq = el.dom.getAttribute('seq-id').split(' ').join('');
				box = AnnoJ.getGUI().InfoBox;
				box.show();
				box.expand();
				box.echo(buildCopyView(cleanedSeq,el.dom.getAttribute('locus_tag')));
			  // closeButton(box.body.dom);
			  box.setTitle("Information: "+el.dom.getAttribute('locus_tag'));
			};

			function buildCopyView(seq,tag){
			  var html = "<div><b>Protein Coding Sequence</b><br/>";
			  html += "<p>"+tag+"</p><br/>"
			  html += "<textarea rows='20' cols='33'>"+seq+"</textarea></div>";

			  return html;
			};

			function closeButton(obj){
			  new Ext.Button({
					text     : 'Close',
					tooltip  : 'Close the information window',
					renderTo : obj,
					handler : function() {
					  c = Annoj.getGUI().LayoutBox
					  c.expand();
					}
				});
			}
		}
});