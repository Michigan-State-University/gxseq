//Browser track for showing genome information
Ext.define('Sv.tracks.BrowserTrack', {
    extend: 'Sv.tracks.DataTrack',
    autoResize: false,
    autoScroll: true,
    minCache: 100,
    scaler: 0.5,
		bioentry: 1,
    dragMode: 'browse',
    initComponent: function() {
        this.callParent(arguments);
        var self = this;
        self.cache = 3 * screen.width;
        self.maxCache = 20 * screen.width;
        self.originalHeight = self.height;
        self.addEvents({
          'open' : true,
          'close': true
        });
        self.contextMenu.addItems(
        [
        self.name,
        '-',
        new Ext.menu.Item(
        {
            text: 'Close track',
            iconCls: 'silk_delete',
            handler: function()
            {
                self.fireEvent('close', self);
            }
        }),
        new Ext.menu.Item(
        {
            text: 'Toggle Toolbar',
            iconCls: 'silk_application',
            handler: function()
            {
                self.toolbar.toggle();
            }
        }),
        '-',
        new Ext.menu.Item(
        {
            text: 'Minimize',
            iconCls: 'silk_arrow_down',
            handler: function()
            {
                self.setHeight(self.minHeight);
                self.fireEvent('resize', self.minHeight);
            }
        }),
        new Ext.menu.Item(
        {
            text: 'Maximize',
            iconCls: 'silk_arrow_up',
            handler: function()
            {
                self.setHeight(self.maxHeight);
                self.fireEvent('resize', self.maxHeight);
            }
        }),
        new Ext.menu.Item(
        {
            text: 'Original Size',
            iconCls: 'silk_arrow_undo',
            handler: function()
            {
                self.setHeight(self.originalHeight);
                self.fireEvent('resize', self.originalHeight);
            }
        })
        ]);
        //Manages the y-scale of the track's data
        Scaler = (function()
        {
            var value = 0.5;

            function get()
            {
                return value;
            };
            function set(v)
            {
                var v = parseFloat(v);
                if (v < 0) v = 0;
                if (v > 1) v = 1;
                value = v;
                self.rescale(v);
                return v;
            };

            return {
                get: get,
                set: set
            };
        })();

        //Singleton object for loading data from the server. Data is managed in chunks called frames
        self.DataManager = (function() {
            var defaultView = {
                //assembly : '',
                position: 0,
                bases: 10,
                pixels: 1
            };
            var views = {
                loading: defaultView,
                requested: defaultView
            };
            var state = {
                busy: false,
                empty: true,
                //assembly : '',
                frameL: 0,
                frameR: 0
            };
            var policy = {
                frame: 10000,
                bases: 10,
                pixels: 1,
                index: 0
            };

            //Check a policy to ensure that it is correctly formed
            function getPolicy(view)
            {
                var p = self.getPolicy(view);

                if (!p) return null;

                if (p.bases == undefined) return null;
                if (p.pixels == undefined) return null;
                if (p.cache == undefined) return null;
                if (p.index == undefined) return null;

                p.bases = parseInt(p.bases) || 0;
                p.pixels = parseInt(p.pixels) || 0;
                p.cache = parseInt(p.cache) || 0;
                p.index = parseInt(p.index) || 0;

                if (p.pixels < 1 || p.bases < 1 || p.cache < 100 * p.bases / p.pixels)
                {
                    return null;
                }
                return p;
            };

            //Get the frame that contains a particular position
            function pos2frame(pos)
            {
                if (pos < 0) pos = 0;
                return Math.floor(Math.abs(pos) / policy.cache);
            };

            //Get the positions of the edges of a frame
            function frame2pos(frame)
            {
                return {
                    left: Math.abs(frame) * policy.cache,
                    right: (Math.abs(frame) + 1) * policy.cache - 1
                };
            };

            //Get the edges of the current view
            function getEdges()
            {
                var half = Math.round(AnnoJ.pixels2bases(self.Frame.ext.getWidth()) / 2);
                var view = AnnoJ.getLocation();
                return {
                    // g1 : (view.position - half)+.5,
                    // g2 : (view.position + half)-.5
                    g1: (view.position - half),
                    g2: (view.position + half)
                };
            };

            //Convert an x position to a genome coordinate (x relative to top left of Frame)
            function convertX(x)
            {
                return Math.round(x * views.current.bases / views.current.pixels);
            };

            //Convert a genome coordinate to an x position (x relative to top left of Frame)
            function convertG(g)
            {
                return Math.round(g * views.current.pixels / views.current.bases);
            };

            //Clear all data from the data structure
            function clear()
            {
                state.empty = true;
                self.clearData();
            };

            //Prune the edges of currently loaded data (uses frames)
            function prune(frameLeft, frameRight)
            {
                if (state.empty) return;

                if (frameLeft > state.right || frameRight < state.left)
                {
                    clear();
                    return;
                }
                if (frameLeft > state.left)
                {
                    state.left = frameLeft;
                }
                if (frameRight < state.right)
                {
                    state.right = frameRight;
                }
                self.pruneData(frame2pos(frameLeft).left, frame2pos(frameRight).right);
            };

            //Parse incoming data from the server
            function parse(data, frame)
            {
                if (state.empty || frame < state.left)
                {
                    state.left = frame;
                }
                if (state.empty || frame > state.right)
                {
                    state.right = frame;
                }
                state.empty = false;

                if (!data) return;

                var pos = frame2pos(frame);

                self.parseData(data, pos.left, pos.right);
            };

            //Get the current data view window
            function getLocation()
            {
                return views.current;
            };

            //Set the current data view window
            function setLocation(requested)
            {
                Ext.apply(views.requested || {},
                requested || views.requested || {},
                defaultView);

                //Lock the track if the request can't be serviced
                var newPolicy = getPolicy(views.requested);
                if (!newPolicy)
                {
                    self.clearCanvas();
                    self.maskFrame('No data available at this zoom level');
                    return;
                }
                self.unmaskFrame();

                //Clear if the policy has changed
                if (policy != newPolicy)
                {
                    clear();
                    self.clearCanvas();
                    policy = newPolicy;
                }

                //Determine the range of data required to service the request
                var bases = self.cache * policy.bases / policy.pixels;
                var frameL = pos2frame(views.requested.position - bases);
                var frameR = pos2frame(views.requested.position + bases);
                
								//TODO: rethink pruning data. Can we keep it?
								//Prune data edges
                prune(frameL, frameR);
                
								//Load data as required
								// TODO: rework the loading queue.. it is hard to manage
                if (state.empty)
                {
                    loadFrame(frameL);
                }
                else if (frameL < state.left)
                {
                    loadFrame(state.left - 1);
                }
                else if (frameR > state.right)
                {
                    loadFrame(state.right + 1);
                }
                //Paint the desired location
                var edges = getEdges();
                //self.paintCanvas(edges.g1, edges.g2, views.requested.bases, views.requested.pixels);
                //try painting a wider region
                var w = edges.g2 - edges.g1
                //TODO: Avoid painting 3 times per load
                self.paintCanvas(edges.g1, edges.g2, views.requested.bases, views.requested.pixels);
            };

            function refresh()
            {
                clear();
                self.clearCanvas();
                self.setLocation(AnnoJ.getLocation());
            };

            //Load data from the server
            function loadFrame(frame)
            {
                if (state.busy) return;
                state.busy = true;
                self.setTitle('<span class="waiting">Updating...</span>');

                views.loading = views.requested;
                //convert to left  -- right
                var pos = frame2pos(frame);
                
                // Check localStorage
                if(self.storeLocal){
                  try {
                    var ls = localStorage.getItem("request_"+self.id+"_"+pos.left+"_"+pos.right+"_"+policy.bases+"_"+policy.pixels+"_"+self.requestFormat()+self.localStoreId())
                  } catch(e){}
                }
                if(ls)
                {
                  response = JSON.parse(ls);
                  setDataFrame(response.data,frame);
                }
                else
                {
                  self.requestFrame( pos,policy,function(r){self.loadSuccess(r,frame,pos,policy)},function(r){self.loadFailure(r)} );
                }
            };
            
            //Set the data returned by server
            function setDataFrame(data,frame)
            {
              if(data) parse(data, frame);
              views.loading = null;
              state.busy = false;
              self.setTitle(self.name);
              if(data){
                //setLocation(views.requested);
                self.fireEvent('frameLoaded',self,getEdges(),views.requested);
              }
            }
            return {
                getLocation: getLocation,
                setLocation: setLocation,
                setDataFrame: setDataFrame,
                getEdges: getEdges,
                convertX: convertX,
                convertG: convertG,
                clear: clear,
                refresh: refresh,
                views : views,
                state : state,
                parse : parse
            };
        })();

       Scaler.set(self.scaler);

			//Convenience aliases
			this.refresh=this.DataManager.refresh;
			this.clearCanvas=this.DataManager.clearCanvas;
			this.getLocation=this.DataManager.getLocation;
			this.setLocation=this.DataManager.setLocation;
			this.getEdges=this.DataManager.getEdges;
			this.convertX=this.DataManager.convertX;
			this.convertG=this.DataManager.convertG;
			this.setScale=Scaler.set;
			this.getScale=Scaler.get;
    },
    loadSuccess : function(response,frame,pos,policy){
      var me = this;
      if(me.storeLocal){
       try{
         var keysArray = JSON.parse(localStorage.getItem('orderedKeys')) || []
         if(keysArray.length >= 10)
         {
           localStorage.removeItem(keysArray.shift());
         }
         var idString = "request_"+me.id+"_"+pos.left+"_"+pos.right+"_"+policy.bases+"_"+policy.pixels+"_"+me.requestFormat()+me.localStoreId();
         keysArray.push(idString);
         localStorage.setItem('orderedKeys',JSON.stringify(keysArray));
         localStorage.setItem(idString, JSON.stringify(response) );
       }
       catch(e){
         console.error(e)
         console.log("Possible Quota limit. Removing last item to try making room")
         //Probably a quota limit error. Remove the last item to make some room
         localStorage.removeItem(keysArray.shift());
       }
      }
      me.DataManager.setDataFrame(response.data,frame);
    },
    loadFailure : function(message){
      var me = this;
      console.error('Failed to load data for track ' + me.name);
      console.error(message)
      me.DataManager.setDataFrame(null)
    },
    // requestFrame runs the ajax request for all data loads in the track
    // Children may override requestFrame to customize behavior
    requestFrame : function(pos,policy,successFunc,failureFunc){
      var me = this;
      Ext.Ajax.request({
          url: me.data,
          method: 'GET',
          params: {
              jrws: Ext.encode({
                  method: me.requestFormat(),
                  param: {
                      id: me.id,
                      experiment: me.experiment,
                      left: pos.left,
                      right: pos.right,
                      bases: policy.bases,
                      pixels: policy.pixels,
                      bioentry: me.bioentry
                  }
              })
          },
          success: function(response)
          {
              response = JSON.parse(response.responseText);
              successFunc(response);
          },
          failure: function(message)
          {
            failureFunc(message);
          }
      });
    },
    requestFormat : function(){
      return 'range';
    },
    //Override to provide custom store ids
    localStoreId : function(){
      return '';
    },
    open : function(){
      var me = this;
      //Syndicate the track if necessary
			if (!me.Syndicator.isSyndicated())
			{
			  me.Syndicator.syndicate({
					success : function()
					{
					  me.fireEvent('open',me)
					},
					failure : function()
					{
						me.maskFrame('Error: track failed to syndicate');
						//close(track);
					}
				});
			}
			else
			{
				me.unmaskFrame();
				me.fireEvent('open',me)
			}
    },
    close: function() {
        this.maskFrame('Track Closed');
        this.DataManager.clear();
        this.removeFrame();
        this.fireEvent('close',this);
    },
    moveCanvas: function(x) {
        this.Canvas.ext.setLeft(x);
    },
    setHeight: function(h) {
        var self = this;
        if (h < self.minHeight) h = self.minHeight;
        if (h > self.maxHeight) h = self.maxHeight;
        self.height = h;
        self.Frame.ext.setHeight(h);
        AnnoJ.resetHeight();
    },
    //Specific functionality for the following methods should be provided by subclasses
    clearCanvas: function() {},
    paintCanvas: function(x1, x2, bases, pixels) {},
    refreshCanvas: function() {},
    clearData: function() {},
    pruneData: function(x1, x2) {},
    parseData: function(data, x1, x2) {},
    getPolicy: function(view) {
        return null;
    },
    rescale: function(value) {},
    color_values: [
       "444444","EEEEEE","FFFF99","DDBB88","B15928","B86948","A6CEE3","1F78B4",
       "000000","AAAAAA","BBBB55","997744","701504","742504","628AA0","0B3470",
       "B2DF8A","33A02C","FB9A99","E31A1C","FDBF6F","FF7F00","CAB2D6","6A3D9A",
       "709B46","006008","B75655","A00608","B97B2B","BB3B00","867092","260956"
     ]
});

