/*
 * The Sequence track displays 
 *	GC content
 *	six frame translation
 *	DNA
 * The display is rendered at multiple levels: GC only, GC plus start/stop, Sequence plus Protein
 * TODO: Refactor multiple handlers
 */
Ext.define('Sv.tracks.SequenceTrack',{
	extend : 'Sv.tracks.BrowserTrack',
	single    : false,
	clsAbove  : 'AJ_above',
	clsMiddle : 'AJ_mid',
	clsBelow  : 'AJ_below',
	slider    : 0.5,
	boxHeight : 20,
	boxHeightMax : 24,
	boxHeightMin : 1,
	bubbleWidth : 3,
	showBubble : false,
	boxBlingLimit : 6,
	initComponent : function(){
		this.callParent(arguments);
		var self = this;

		//Initialize the DOM elements
		var containerA = new Ext.Element(document.createElement('DIV'));
	  var containerMid = new Ext.Element(document.createElement('DIV'));
	  var containerB = new Ext.Element(document.createElement('DIV'));

		containerA.addCls(self.clsAbove);
	  containerMid.addCls(self.clsMiddle);
	  containerB.addCls(self.clsBelow);

		//Force some styles
		containerA.setStyle('position', 'relative');
	  containerMid.setStyle('position', 'relative');
	  containerB.setStyle('position', 'relative');
		containerA.setStyle('width', '100%');
		containerMid.setStyle('width', '100%');
	  containerB.setStyle('width', '100%');

		if (self.single)
		{
			containerA.setStyle('height', self.Canvas.ext.getHeight());
			containerB.setStyle('display', 'none');
		}
		else
		{
			containerA.setStyle('height', '40%');
			containerMid.setStyle('height', '20%');
			containerB.setStyle('height', '40%');
			//containerB.setStyle('margin-top','20px');
			//containerMid.setStyle('borderBottom', 'dotted black 1px');
		}
		containerA.appendTo(self.Canvas.ext);
	    containerMid.appendTo(self.Canvas.ext);
	    containerB.appendTo(self.Canvas.ext);


		var SixFrameClose = (function()
		{
	    var dataA = new SixFrameList();
	    var dataMid = new SequenceList();
	    var dataB = new SixFrameList();

			function parse(data)
			{
        for (var series in data)
        {
          addLabel(series);
        }
        dataA.parse_upper(data);
        dataMid.parse(data);
        dataB.parse_lower(data);
			};


			var canvasA = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : true,
				showCodons : false
			});

			var canvasMid = new Sv.painters.SequenceCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit
			});

			var canvasB = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : true,
				showCodons : false
			});

	        canvasB.flipY();


			function paint(left, right, bases, pixels)
			{

				var subsetA = dataA.subset2canvas_upper(left, right, bases, pixels);
				var subsetMid = dataMid.subset2canvas(left, right, bases, pixels);
				var subsetB = dataB.subset2canvas_lower(left, right, bases, pixels);
				canvasA.setData(subsetA);
				canvasMid.setData(subsetMid);
				canvasB.setData(subsetB);

				canvasA.paint();
				canvasMid.paint();
				canvasB.paint();
			};

			return {
        dataA : dataA,
        dataMid : dataMid,
        dataB : dataB,
        canvasA : canvasA,
        canvasMid : canvasMid,
        canvasB : canvasB,
        parse : parse,
        paint : paint
			};
		})();

		var SixFrameFar = (function()
		{
	    var dataA = new SixFrameList();
	    var dataMid = new SequenceList();
	    var dataB = new SixFrameList();

			function parse(data)
			{
		      for (var series in data)
		      {
					addLabel(series);
		      }
				//turn off the sequence data

				dataA.parse_upper(data);
				dataMid.parse(data);
	            dataB.parse_lower(data);
			};


			var canvasA = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

			var canvasMid = new Sv.painters.SequenceCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit
			});

			var canvasB = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

	        canvasB.flipY();


			function paint(left, right, bases, pixels)
			{
        containerA.setStyle('height', '40%');
	  		    containerMid.setStyle('height', '20%');
	  		    containerB.setStyle('height', '40%');
				var subsetA = dataA.subset2canvas_upper(left, right, bases, pixels);
				var subsetMid = dataMid.subset2canvas(left, right, bases, pixels);
				var subsetB = dataB.subset2canvas_lower(left, right, bases, pixels);
				canvasA.setData(subsetA);
				canvasMid.setData(subsetMid);
				canvasB.setData(subsetB);

				canvasA.paint();
				canvasMid.paint();
				canvasB.paint();
			};

			return {
				dataA : dataA,
				dataMid : dataMid,
	      	    dataB : dataB,
				canvasA : canvasA,
				canvasMid : canvasMid,
	      	    canvasB : canvasB,
				parse : parse,
				paint : paint
			};
		})();

		var SixFrameOnly = (function()
		{
	    var dataA = new SixFrameList();
	    var dataMid = new SequenceList();
	    var dataB = new SixFrameList();

			function parse(data)
			{
		      for (var series in data)
		      {
					addLabel(series);
		      }
				dataA.parse_upper(data);
				dataMid.parse(data);
	            dataB.parse_lower(data);
			};


			var canvasA = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

			var canvasMid = new Sv.painters.SequenceCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit
			});

			var canvasB = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

	        canvasB.flipY();


			function paint(left, right, bases, pixels)
			{
				var subsetA = dataA.subset2canvas_upper(left, right, bases, pixels);
				var subsetMid = dataMid.subset2canvas(left, right, bases, pixels);
				var subsetB = dataB.subset2canvas_lower(left, right, bases, pixels);
				canvasA.setData(subsetA);
	            canvasMid.setData(subsetMid);
				canvasB.setData(subsetB);
        containerA.setStyle('height', '40%');
	  		    containerMid.setStyle('height', '20%');
	  		    containerB.setStyle('height', '40%');
				canvasA.paint();
	            canvasMid.paint();
				canvasB.paint();
			};

			return {
				dataA 	: dataA,
				dataMid : dataMid,
	            dataB 	: dataB,
				canvasA : canvasA,
				canvasMid : canvasMid,
	            canvasB : canvasB,
				parse 	: parse,
				paint 	: paint
			};
		})();

		var GCContent = (function()
		{
	    var dataA = new SixFrameList();
	    var dataMid = new SeriesList();
	    var dataB = new SixFrameList();

			function parse(data)
			{
		      for (var series in data)
		      {
					addLabel(series);
		      }
				dataA.parse_upper(data);
	            dataMid.parse(data);
	            dataB.parse_lower(data);
			};


			var canvasA = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

			var canvasMid = new Sv.painters.LineChartCanvas({
				scaler : self.slider,
	            boxHeight : self.boxHeight,
	            boxHeightMax : self.boxHeightMax,
	            boxHeightMin : self.boxHeightMin,
	            boxBlingLimit : self.boxBlingLimit
			});

			var canvasB = new Sv.painters.SixFrameCanvas({
				scaler : self.slider,
				boxHeight : self.boxHeight,
				boxHeightMax : self.boxHeightMax,
				boxHeightMin : self.boxHeightMin,
				boxBlingLimit : self.boxBlingLimit,
				showProteins : false,
				showCodons : true
			});

	        canvasB.flipY();


			function paint(left, right, bases, pixels)
			{

				var subsetA = dataA.subset2canvas_upper(left, right, bases, pixels);
				var subsetMid = dataMid.subset2canvas(left, right, bases, pixels);
				var subsetB = dataB.subset2canvas_lower(left, right, bases, pixels);
				canvasA.setData(subsetA);
				canvasMid.setData(subsetMid);
				canvasB.setData(subsetB);

				containerA.setStyle('height', '40%');
	  		    containerMid.setStyle('height', '20%');
	  		    containerB.setStyle('height', '40%');

				canvasA.paint();
				canvasMid.paint();
				canvasB.paint();
			};

			return {
				dataA : dataA,
				dataMid : dataMid,
	      	    dataB : dataB,
				canvasA : canvasA,
				canvasMid : canvasMid,
	      	    canvasB : canvasB,
				parse : parse,
				paint : paint
			};
		})();


	  var GCContentOnly = (function()
		{
	        var dataMid = new SeriesList();
	        var dataA = new SixFrameList();
	        var dataB = new SixFrameList();
			function parse(data)
			{
	            dataMid.parse(data);
			};

			var canvasA = new Sv.painters.SixFrameCanvas({
			});
	        var canvasB = new Sv.painters.SixFrameCanvas({
			});

			var canvasMid = new Sv.painters.LineChartCanvas({
				scaler : self.slider,
	            boxHeight : self.boxHeight,
	            boxHeightMax : self.boxHeightMax,
	            boxHeightMin : self.boxHeightMin,
	            boxBlingLimit : self.boxBlingLimit
			});	

			function paint(left, right, bases, pixels)
			{
				var subsetMid = dataMid.subset2canvas(left, right, bases, pixels);
				canvasMid.setData(subsetMid);

				containerA.setStyle('height', '0%');
	  		    containerMid.setStyle('height', '100%');
	  		    containerB.setStyle('height', '0%');

				canvasMid.paint();
			};

			return {
			    dataA 	: dataA,
	            dataB 	: dataB,
				dataMid : dataMid,
	            canvasA : canvasA,
				canvasMid : canvasMid,
	            canvasB : canvasB,
				parse : parse,
				paint : paint
			};
		})();


		//Data handling and rendering object
		var handler = SixFrameClose;
		var handlerList = [SixFrameClose, SixFrameFar, SixFrameOnly, GCContent, GCContentOnly];
		//Data series labels
		var labels = null;
    
    //Select Event
    // enable
	 	this.removeListener("selectStart",this.cancelSelectStart);
    
    this.on("selectEnd", function(startPos,endPos){
      if(startPos <0) startPos=0;
      //Grab some state information
      // var bases = self.DataManager.views.requested.bases;
      // var pixels = self.DataManager.views.requested.pixels;
      //create the readsDisplay
      //console.log(self.readsDisplay.create(startPos,endPos,bases,pixels));
      var win = Ext.create('Sv.gui.SequenceWindow',{
        startBase : startPos,
        endBase : endPos,
        title : startPos+" - "+endPos+" : "+self.name
      })      
      win.show();
    });
    
    Ext.define('Sv.gui.SequenceWindow',{
      extend:'Ext.Window',
      x: 100,
      y: 450,
      width:425,
      maxHeight:800,
      maxWidth:1000,
      minWidth:400,
      height:300,
      plain:true,
      layout:'fit',
      border:false,
      closable:true,
      startBase:0,
      startBase:1,
      items: [
        {
          xtype : 'panel',
          itemId : 'bodyPanel',
          autoScroll:true,
        }
      ],
      initComponent : function(){
        this.callParent(arguments);
        var me = this;
        me.loadData(function(response){
          me.getComponent('bodyPanel').update(response);
        });        
      },
      loadData : function(successFunc){
        var me = this;
        Ext.Ajax.request({
           url: self.data+'sequence',
           method: 'GET',
           params: {
             id: self.id,
             sample: self.sample,
             left: me.startBase,
             right: me.endBase,
             bioentry: self.bioentry
           },
           success: function(response)
           { 
             successFunc(response.responseText);

           },
           failure: function(message)
           { 
             successFunc('Request Sequence failed:'+ '(' + message + ')');
           }
         });
      },
    });
		//Add series name to context menu (checkbox controls series visibility)
		function addLabel(name)
		{
			if (!labels)
			{
				self.contextMenu.addItems(['-','Series']);
				labels = {};
			}

			if (labels[name] == undefined)
			{
				labels[name] = true;

				self.contextMenu.addItems([
					new Ext.menu.CheckItem(
					{
						text    : name,
						checked : true,
						handler : function()
						{
							var i = 0;
							while(i<handlerList.length){
									handlerList[i].canvasA.groups.toggle(name, this.checked);
									handlerList[i].canvasMid.groups.toggle(name, this.checked);
									handlerList[i].canvasB.groups.toggle(name, this.checked);
									i++
							};

							handler.canvasA.refresh();
							handler.canvasMid.refresh();
							handler.canvasB.refresh();
						}
					})
				]);
			}
		};	

		//Zoom policies (dictate which handler to use)
		var policies = [
			 	      { index:6,  min:1/20,	  max:1/5,    bases:1,    pixels:10,cache:1000,     handler:"SixFrameClose" },
	            { index:7,  min:1/5,    max:1/1,    bases:1,    pixels:5, cache:1000,     handler:"SixFrameFar" },
			 	      { index:8,  min:2/1, 	  max:9/1,    bases:2, 	  pixels:1, cache:10000,    handler:"GCContent" },
	            { index:9,  min:10/1,   max:40/1,   bases:10,   pixels:1, cache:100000,   handler:"GCContentOnly" },
	            { index:10, min:50/1,   max:90/1,   bases:50,   pixels:1, cache:100000,   handler:"GCContentOnly" },
	            { index:11, min:100/1,  max:400/1,  bases:100,  pixels:1, cache:1000000,  handler:"GCContentOnly" },
	            { index:12, min:500/1,  max:900/1,  bases:500,  pixels:1, cache:1000000,  handler:"GCContentOnly" },
	            { index:13, min:1000/1, max:4000/1, bases:1000, pixels:1, cache:10000000, handler:"GCContentOnly" },
	            { index:14, min:5000/1, max:9000/1, bases:5000, pixels:1, cache:10000000, handler:"GCContentOnly" },
	            { index:15, min:10000/1,max:100000/1,bases:10000,pixels:1,cache:100000000,handler:"GCContentOnly" }
		];

		this.getPolicy = function(view)
		{
	    var ratio = view.bases / view.pixels;

	    for (var i=0; i<policies.length; i++)
	    {
	     if (ratio <= policies[i].max && ratio >= policies[i].min)
	     { 
		    handler = eval(policies[i].handler);
			  handler.canvasA.setContainer(null);
		    handler.canvasMid.setContainer(null);
		    handler.canvasB.setContainer(null);
			  handler.canvasA.setContainer(containerA.dom);
		    handler.canvasMid.setContainer(containerMid.dom);
		    handler.canvasB.setContainer(containerB.dom);
	       return policies[i];
	     }
	    }
	    return null;
		};

		this.rescale = function(f)
		{
			handler.canvasA.setScaler(f);
	    handler.canvasMid.setScaler(f);
	    handler.canvasB.setScaler(f);
	    handler.canvasA.refresh(true);
	    handler.canvasMid.refresh(true);
	    handler.canvasB.refresh(true);

		};

		this.clearCanvas = function()
		{
			handler.canvasA.clear();
	    handler.canvasMid.clear();
	    handler.canvasB.clear();
		};

		this.paintCanvas = function(l,r,b,p)
		{
			handler.paint(l,r,b,p);
		};

		this.refreshCanvas = function()
		{
			handler.canvasA.refresh(true);
	    	handler.canvasMid.refresh(true);
	    	handler.canvasB.refresh(true);
		};

		this.resizeCanvas = function()
		{
	    handler.canvasA.refresh(true);
	    handler.canvasMid.refresh(true);
	    handler.canvasB.refresh(true);
		};

		this.clearData = function()
		{
			handler.dataA.clear();
	    handler.dataMid.clear();
	    handler.dataB.clear();
	    //this.Seqzoom.hide();
		};

		this.pruneData = function(a,b)
		{
			handler.dataA.prune(a,b);
	    handler.dataMid.prune(a,b);
	    handler.dataB.prune(a,b);
		};

		this.parseData = function(data)
		{
			handler.parse(data);
		};

      // //The mouse Seqzoom tracks the mouse as it moves around the screen
      // this.Seqzoom = (function()
      // {
      //  var ext = Ext.get(document.createElement('DIV'));
      //  var pageX;
      //  var offset;
      //  ext.addCls('AJ_mouse_label');
      //  ext.appendTo(self.Canvas.ext);
      //  //Movement over the text
      //         ext.on('mousemove', function(event)
      //           {
      //             offset = AnnoJ.bases2pixels(getEdges().g1);
      //             pageX = event.getPageX() - this.getX();
      //             updateView();
      //           },
      //           self.Canvas.ext
      //         );
      //         //Clear away the Seqzoom when we hover over something else (Mouseout fires too often because of the layered divs)
      //         containerA.on('mouseover', function(event){hide();});
      //         containerB.on('mouseover', function(event){hide();});
      //         //Attach to the mouse move event
      //         //hidden movement over the canvas
      //         self.Canvas.ext.on('mousemove', function(event)
      //           {
      //               offset = AnnoJ.bases2pixels(getEdges().g1);
      //               pageX = event.getPageX() - this.getX();
      //               updateView();
      //           },
      //           self.Canvas.ext,
      //           {
      //             delegate : "."+self.clsMiddle
      //           }
      //         );
      // 
      //  function updateView(){
      //    if(!handler.dataMid||!handler.dataMid.get) return;
      //    setText('<div>' + handler.dataMid.get(AnnoJ.pixels2bases(pageX + offset)-3, 7) + '</div>');
      //    show();
      //    ext.setLeft(pageX - Math.round(ext.getWidth()/2));
      //    ext.setTop((self.Canvas.ext.getHeight() / 2)-(self.boxHeight)/2);
      //  };
      // 
      //  function getEdges()
      //  {
      //    var half = Math.round(AnnoJ.pixels2bases(self.Canvas.ext.getWidth())/2);
      //    var view = AnnoJ.getLocation();
      // 
      //    return {
      //      g1 : view.position - half,
      //      g2 : view.position + half
      //    };
      //  };
      //  function setText(text)
      //  {
      //    ext.update(text);
      //  };
      // 
      //  function show()
      //  {
      //    ext.setDisplayed(true);
      //    ext.setLeft(pageX - Math.round(ext.getWidth()/2) + 2);
      //    ext.setTop(ext.getHeight()/2);
      //  }
      // 
      //  function hide(){ext.setDisplayed(false);}
      //  function setDisplayed(state){state ? show() : hide();};
      // 
      //  return {
      //    setText : setText,
      //    setDisplayed : setDisplayed,
      //    show : show,
      //    hide : hide
      //  };
      // })();
	},
  getConfig: function(){
    var track = this;
    return {
      id : track.id,
      name : track.name,
      data : track.data,
      height : track.height,
      scale : track.scale,
      showControls : track.showControls,
    }
  }
});
