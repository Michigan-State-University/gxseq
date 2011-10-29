/*
 * Protein Sequence Track
 *
 */
Ext.define('Sv.tracks.ProteinSequenceTrack',{
	extend : 'Sv.tracks.BrowserTrack',
	single    : true,
	clsMiddle : 'AJ_mid',
	slider    : 0.5,
	boxHeight : 20,
	boxHeightMax : 24,
	boxHeightMin : 1,
	bubbleWidth : 3,
	//showBubble : false,
	boxBlingLimit : 6,
	initComponent : function(){
		this.callParent(arguments);
		var self = this;
		//Initialize the DOM elements
		var containerA = new Ext.Element(document.createElement('DIV'));

		containerA.addCls(self.config.clsMiddle);

		//Force some styles
		containerA.setStyle('position', 'relative');
	  containerA.setStyle('width', '100%');
		containerA.setStyle('height', '100%'); //self.Canvas.ext.getHeight());

		containerA.appendTo(self.Canvas.ext);

		var ProteinSequenceOnly = (function()
		{
	    var dataA = new ProteinSequenceList();

			function parse(data)
			{
		      for (var series in data)
		      {
	        // addLabel(series);
		      }
				//turn off the sequence data

				dataA.parse(data);
			};


			var canvasA = new Sv.painters.ProteinSequenceCanvas({
				scaler : self.config.slider,
				boxHeight : self.config.boxHeight,
				boxHeightMax : self.config.boxHeightMax,
				boxHeightMin : self.config.boxHeightMin,
				boxBlingLimit : self.config.boxBlingLimit
			});


			function paint(left, right, bases, pixels)
			{
				var subsetA = dataA.subset2canvas(left, right, bases, pixels);

				canvasA.setData(subsetA);

				canvasA.paint();
			};

			return {
				dataA 	: dataA,
				canvasA : canvasA,
				parse 	: parse,
				paint 	: paint
			};
		})();

		//Data handling and rendering object
		var handler = ProteinSequenceOnly;
	  // var handlerList = [ProteinSequenceClose, ProteinSequenceFar, ProteinSequenceOnly];
	  var handlerList = [ProteinSequenceOnly];
		//Data series labels
		var labels = null;

		//Add series name to context menu (checkbox controls series visibility)
		function addLabel(name)
		{
			if (!labels)
			{
				self.ContextMenu.addItems(['-','Series']);
				labels = {};
			}

			if (labels[name] == undefined)
			{
				labels[name] = true;

				self.ContextMenu.addItems([
					new Ext.menu.CheckItem(
					{
						text    : name,
						checked : true,
						handler : function()
						{
							//Update ALL handlers to make toggling persistent
							var i = 0;
							while(i<handlerList.length){
									handlerList[i].canvasA.groups.toggle(name, !this.checked);
									i++
							};
	            handler.canvasA.refresh();
						}
					})
				]);
			}
		};	

		//Zoom policies (dictate which handler to use)
		var policies = [
	      { index:7, min:1/20, max:1/1,    bases:1,  pixels:10,  cache:10000, handler:"ProteinSequenceOnly" },
	      { index:8, min:1/5,  max:1/1,    bases:1,  pixels:5,   cache:10000, handler:"ProteinSequenceOnly" },
	      // { index:9, min:1/1,  max:10/1,   bases:1,  pixels:1,   cache:100000,handler:"ProteinSequenceOnly" }
		];

		this.getPolicy = function(view)
		{
	    var ratio = view.bases / view.pixels;

	    for (var i=0; i<policies.length; i++)
	    {
	     if (ratio <= policies[i].max && ratio >= policies[i].min)
	     { 
		    handler = eval(policies[i].handler);
	      // handler.canvasA.setContainer(null);
	      handler.canvasA.setContainer(containerA.dom);
	       return policies[i];
	     }
	    }
	    return null;
		};

		this.rescale = function(f)
		{
			handler.canvasA.setScaler(f);
	    handler.canvasA.refresh(true);

		};

		this.clearCanvas = function()
		{
			handler.canvasA.clear();
		};

		this.paintCanvas = function(l,r,b,p)
		{
			handler.paint(l,r,b,p);
		};

		this.refreshCanvas = function()
		{
			handler.canvasA.refresh(true);
		};

		this.resizeCanvas = function()
		{
	    handler.canvasA.refresh(true);
		};

		this.clearData = function()
		{
			handler.dataA.clear();
		};

		this.pruneData = function(a,b)
		{
			handler.dataA.prune(a,b);
		};

		this.parseData = function(data)
		{
			handler.parse(data);
		};

			//The mouse Seqzoom tracks the mouse as it moves around the screen
			this.Seqzoom = (function()
			{
				var ext = Ext.get(document.createElement('DIV'));
				var pageX;
				var offset;
				ext.addCls('AJ_mouse_label');
				ext.appendTo(self.Canvas.ext);


				function updateView(){
					setText('<div>' + handler.dataMid.get(AnnoJ.pixels2bases(pageX + offset)-3, 7) + '</div>');
					show();
					ext.setLeft(pageX - Math.round(ext.getWidth()/2));
					console.log("Seqzoom UpdateView Called")
					ext.setTop((self.Canvas.ext.getHeight() / 2)-(self.config.boxHeight)/2);
				};

				function getEdges()
				{
					var half = Math.round(AnnoJ.pixels2bases(self.Canvas.ext.getWidth())/2);
					var view = AnnoJ.getLocation();

					return {
						g1 : view.position - half,
						g2 : view.position + half
					};
				};
				function setText(text)
				{
					ext.update(text);
				};

				function show()
				{
					ext.setDisplayed(true);
					ext.setLeft(pageX - Math.round(ext.getWidth()/2) + 2);
					ext.setTop(ext.getHeight()/2);
				}

				function hide(){ext.setDisplayed(false);}
				function setDisplayed(state){state ? show() : hide();};

				return {
					setText : setText,
					setDisplayed : setDisplayed,
					show : show,
					hide : hide
				};
			})();
	}
});