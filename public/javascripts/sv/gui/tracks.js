//Tracks GUI component presents all tracks in the main component of the viewport
AnnoJ.Tracks = function(userConfig)
{
  var self = this;
  
  //Create the body div manually. Add touch events.
  tracks_body_div = document.createElement("DIV"); 
  tracks_body_div.id = "tracks_body_div";
  tracks_body_div.setAttribute("ontouchstart", "this.handleTouchStart(event);")
  tracks_body_div.setAttribute("ontouchmove", "this.handleTouchMove(event);")
  tracks_body_div.setAttribute("ontouchend", "this.handleTouchEnd(event);")
  
  //Get our ext element
  body = new Ext.Element(tracks_body_div);

  body.addCls('AJ_tracks');
  
  var defaultConfig = {
    region         : 'center',
    iconCls        : 'silk_bricks',
    deferredRender : true,
    contentEl      : body,
    autoScroll     : false,
    margin         : '0 0 0 0',
    layout      : 'fit'
  };
  var config = defaultConfig;
  
  Ext.apply(config, userConfig || {}, defaultConfig);

  AnnoJ.Tracks.superclass.constructor.call(this, config);
  
  self.addEvents({
    'dragStarted'   : true,
    'dragCancelled' : true,
    'dragEnded'     : true,
    'dragged'       : true,
    'dragModeSet'   : true,
    'refresh'       : true,
    'browse'        : true
  });
  
  //Location for internal tracking
  var location = {}
  
  //Mouse object tracks mouse state for element
  var mouse = {
    x : 0,
    y : 0,
    down : false,
    drag : false,
    downX : 0,
    downY : 0
  };
  
  // Open an api to the track manager's body for external use
  this.getBody = function(){
      return body;
  }
  this.getMouse = function(){
      return mouse;
  }
  // Touch event functions
  tracks_body_div.handleTouchStart= function(e){
    //e.preventDefault();
    trackManager = self;
    body = trackManager.getBody();
    mouse = trackManager.getMouse();
    if (event.target.tagName == 'INPUT') return;
    mouse.drag = false;
    mouse.down = true;
    mouse.downX = e.touches[0].pageX - body.getX();
    mouse.downY = e.touches[0].pageY - body.getY();
  };

  tracks_body_div.handleTouchEnd = function(e){
    //e.preventDefault();
    trackManager = self;
    body = self.getBody();
    mouse = self.getMouse();
    if (!mouse.down) return;
    mouse.down = false;

    if (mouse.drag)
    {
      mouse.drag = false;
      trackManager.fireEvent('dragEnded', {
        x : mouse.x,
        y : mouse.y
      });
    }
  };

  tracks_body_div.handleTouchMove = function(e){
    e.preventDefault();
    trackManager = self
    body = trackManager.getBody();
    mouse = trackManager.getMouse();
    mouse.x = e.touches[0].pageX - body.getX();
    mouse.y = e.touches[0].pageY - body.getY();
    if (!mouse.down) return;
    if (!mouse.drag)
    {
      mouse.drag = true;
      trackManager.fireEvent('dragStarted', {
        x : mouse.x,
        y : mouse.y,
        pageX : e.touches[0].pageX,
        pageY : e.touches[0].pageY
      });
      return;
    }
    trackManager.fireEvent('dragged', {
      x1 : mouse.downX,
      y1 : mouse.downY,
      x2 : mouse.x,
      y2 : mouse.y
    });
  }
    
  // Mouse events
  body.on('mousedown', function(event)
  {
      
    if (event.button != 0) return;
    if (event.target.tagName == 'INPUT') return;
    // Stop the standard mousedown, but blur any focus
    event.stopEvent();
    document.activeElement.blur();
    
    mouse.drag = false;
    mouse.down = true;
    mouse.downX = mouse.x;
    mouse.downY = mouse.y;
  });
  body.on('mousemove', function(event)
  {
    mouse.x = event.getPageX() - this.getX();
    mouse.y = event.getPageY() - this.getY();
    if (!mouse.down) return;

    if (!mouse.drag)
    {
      mouse.drag = true;
      self.fireEvent('dragStarted', {
        x : mouse.x,
        y : mouse.y,
        pageX : event.getPageX(),
        pageY : event.getPageY()
      });
      return;
    }
    self.fireEvent('dragged', {
      x1 : mouse.downX,
      y1 : mouse.downY,
      x2 : mouse.x,
      y2 : mouse.y
    });
  });
  
  Ext.EventManager.addListener(window, 'mouseup', function(event)
  {
    if (event.button != 0) return;
    if (!mouse.down) return;
    mouse.down = false;

    if (mouse.drag)
    {
      mouse.drag = false;
      self.fireEvent('dragEnded', {
        x : mouse.x,
        y : mouse.y
      });
    }
  });
  Ext.EventManager.addListener(window, 'keydown', function()
  {
    if (mouse.drag)
    {
      mouse.drag = false;
      mouse.down = false;
      
      self.fireEvent('dragCancelled');
    }
  });
  
  //Dragmode controls
  var dragMode = 'browse';
  
  this.setDragMode = function(mode, broadcast)
  {
    if (mouse.drag)
    {
      mouse.drag = false;
      self.fireEvent('dragCancelled');
    }
    if (mode == dragMode) return;
    
    switch (mode)
    {
      case 'browse': dragMode = mode; break;
      case 'zoom'  : dragMode = mode; break;
      case 'scale' : dragMode = mode; break;
      case 'resize': dragMode = mode; break;
      case 'select':dragMode = mode; break;
      default : dragMode = 'browse';
    }
    
    if (broadcast)
    {
      self.fireEvent('dragModeSet', dragMode);
    }
  };
  this.getDragMode = function()
  {
    return dragMode;
  };
  
  //The mouse label tracks the mouse as it moves around the screen
  this.MouseLabel = (function()
  {
    var ext = Ext.get(document.createElement('DIV'));
    ext.addCls('AJ_mouse_label');
    ext.appendTo(body);
    show();
    
    //Attach to the mouse move event
    body.on('mousemove', function(event)
    {
      var offset = AnnoJ.bases2pixels(getEdges().g1);
      if (mouse.drag)
      {
        if (dragMode == 'zoom' || dragMode == 'select')
        {
          show();
          showText('<div>' + AnnoJ.pixels2bases(mouse.x + offset) + '</div>&darr;');
        }
        else if (dragMode == 'scale')
        {
          hide();
        }
        else
        {
          show();
        }
      }
      else
      {
        show();
        showText('<div>' + AnnoJ.pixels2bases(mouse.x + offset) + '</div>&darr;');
      }
      ext.setLeft(mouse.x - Math.round(ext.getWidth()/2));
      ext.setTop(mouse.y - ext.getHeight() - 5);
    });
    
    function getEdges()
    {
      var half = Math.round(AnnoJ.pixels2bases(body.getWidth())/2);
      var view = AnnoJ.getLocation();
      
      return {
        g1 : view.position - half,
        g2 : view.position + half
      };
    };
    function showText(text)
    {
      ext.update(text);
      setDisplayed(true);
    };
    function showCoord()
    {
      var edges = self.getEdges();
      var offset = AnnoJ.bases2pixels(edges.g1);
      showText('<div>' + AnnoJ.pixels2bases(mouse.x + offset) + '</div>&darr;');
    };
    function show()
    {
      ext.setDisplayed(true);
      ext.setLeft(mouse.x - Math.round(ext.getWidth()/2) + 2);
      ext.setTop(mouse.y - ext.getHeight() - 5);
    }
    function hide()
    {
      ext.setDisplayed(false);
    }
    function setDisplayed(state)
    {
      state ? show() : hide();
    };
    
    return {
      showText : showText,
      showCoord : showCoord,
      setDisplayed : setDisplayed,
      show : show,
      hide : hide
    };
  })();
  
  //The scaler is shown when the user drags while in scale mode
  this.Scaler = (function()
  {
    var container = Ext.get(document.createElement('DIV'));
    container.setStyle('position', 'absolute');
    container.setStyle('z-index', '9999');
    container.appendTo(body);

    var bg = Ext.get(document.createElement('DIV'));
    var fg = Ext.get(document.createElement('DIV'));
    bg.appendTo(container);
    fg.appendTo(container);
    bg.addCls('AJ_scaler_bg');
    fg.addCls('AJ_scaler_fg');
    bg.setStyle('position', 'absolute');
    fg.setStyle('position', 'absolute');
    fg.setBottom(0);
    fg.setLeft(0);
    bg.setTop(0);
    bg.setLeft(fg.getWidth());
    
    var track = null;
    var scale = 1;
    var start = 1;

    container.hide();
    
    function showAt(x,y)
    {
      track = self.tracks.mouse2track(x,y);
      
      if (!track || !track.getScale || !track.setScale)
      {
        track = null;
        return;
      }
      
      var val = track.getScale();
      setScale(val);
      start = scale;

      fg.setLeft(0);
      bg.setLeft(fg.getWidth());
      container.show(true);
      
      container.setX(x - fg.getWidth() - Math.round(bg.getWidth()/2));
      container.setY(y - (1-scale) * bg.getHeight() - body.getScroll().top);
    };
    
    function hide()
    {
      container.hide(true);
    };
    
    function update(offset)
    {
      var shift = offset / bg.getHeight();
      var target = start + shift;
      
      if (target < 0 || target > bg.getHeight()) return;
      
      setScale(target);     
    };
    
    function setScale(v)
    {
      if (!track) return;
      
      if (v > 1) v = 1;
      if (v < 0) v = 0;
      
      var rounded = Math.round(20*v) / 20;

      if (scale == rounded)
      {
        return;
      }
      scale = rounded;
      
      track.setScale(scale);
      
      var px = bg.getHeight() - Math.round(scale * bg.getHeight());
      
      fg.setTop(px - Math.round(fg.getHeight()/2));
    };
    
    function getScale()
    {
      return scale;
    };
    
    //Add mouse listeners
    self.on('dragStarted',function(mouse){
      if (dragMode != 'scale') return;
      showAt(mouse.pageX, mouse.pageY);
    });

    self.on('dragEnded', function()
    {
      if (dragMode != 'scale') return;
      hide();
    });
    self.on('dragged', function()
    {
      if (dragMode != 'scale') return;
      update(mouse.downY - mouse.y);
    });
    
    return {};
  })();
  
  //Resizer is used to resize a track
  this.Resizer = (function()
  {
    var box = Ext.get(document.createElement('DIV'));
    box.addCls('AJ_resizer');
    box.setStyle('position', 'absolute');
    box.appendTo(body);
    box.hide();
        
    var height = 0;
    var track = null;
    
    function bind(track)
    {
      box.setTop(track.getY() - body.getY());
      box.setLeft(0);
      box.setWidth(track.getWidth());
      box.setHeight(track.getHeight());
            
      height = box.getHeight();
      
      show();
    };
    function show()
    {
      box.show();
    };
    function hide()
    {
      track = null;
      box.hide(true);
    };
        
    //Add mouse listeners
    // body.on('mousedown', function(event)
    // {
    //   if (event.button != 0) return;
    //   if (dragMode != 'resize') return;
    //   if (event.getTarget().tagName == 'INPUT') return;
    //   track = self.tracks.mouse2track(event.getPageX(), event.getPageY());
    // 
    //   if (!track)
    //   {
    //     track = null;
    //     return;
    //   }
    //   bind(track);
    // });
    // body.on('mouseup', function(event)
    // {
    //   if (dragMode != 'resize') return;
    //   if (event.getTarget().tagName == 'INPUT') return;
    //   if(!track || !box) {hide(); return}
    //   track.setHeight(box.getHeight());
    //   track.refreshCanvas();
    //   hide();
    // });
    self.on('dragStarted', function(mouse){
      if (dragMode != 'resize') return;
      track = self.tracks.mouse2track(mouse.pageX, mouse.pageY)
      if (!track){
        track = null;
        return;
      }
      bind(track);
    });
    self.on('dragged', function()
    {
      if (dragMode != 'resize' || !track) return;
      var h = height + mouse.y - mouse.downY;
      if (h < track.getMinHeight()) return;
      if (h > track.getMaxHeight()) return;
      box.setHeight(height + mouse.y - mouse.downY);
      track.setHeight(box.getHeight());
    });
    self.on('dragEnded', function()
    {
      if (dragMode != 'resize' || !track) return;
      track.setHeight(box.getHeight());
      track.refreshCanvas();
      hide();
    });
    self.on('dragCancelled', function()
    {
      if (dragMode != 'resize' || !track) return;
      hide();
    });   
    
    return {
      show : show,
      hide : hide
    };
    
  })();

  //Crosshairs that track the mouse
  this.CrossHairs = (function()
  {
    var gap = 5;
    var showNS = true;
    var showEW = false;
    
    var north = Ext.get(document.createElement('DIV'));
    var south = Ext.get(document.createElement('DIV'));
    var east = Ext.get(document.createElement('DIV'));
    var west = Ext.get(document.createElement('DIV'));
    
    north.addCls('AJ_crosshair');
    south.addCls('AJ_crosshair');
    east.addCls('AJ_crosshair');
    west.addCls('AJ_crosshair');
    
    north.setStyle({
      position   : 'absolute',
      top        : 0,
      width      : 0,
      height     : 0,
      borderLeft : 'dotted red 1px'
    });
    south.setStyle({
      position   : 'absolute',
      top        : 0,
      width      : 0,
      height     : '100%',
      borderLeft : 'dotted red 1px'
    });
    east.setStyle({
      position  : 'absolute',
      left      : 0,
      width     : '100%',
      height    : 0,
      borderTop : 'dotted red 1px'
    });
    west.setStyle({
      position  : 'absolute',
      left      : 0,
      width     : 0,
      height    : 0,
      borderTop : 'dotted red 1px'
    });
    
    north.appendTo(body);
    south.appendTo(body);
    east.appendTo(body);
    west.appendTo(body);
    
    toggleNS(showNS);
    toggleEW(showEW);
    
    function setGap(n)
    {
      gap = Math.max(parseInt(n) || 0, 0);
    };
    function toggleNS(state)
    {
      showNS = state ? true : false;
      north.setDisplayed(showNS);
      south.setDisplayed(showNS);
    };
    function toggleEW(state)
    {
      showEW = state ? true : false;
      east.setDisplayed(showEW);
      west.setDisplayed(showEW);
    };
    function setXY(x,y)
    {
      var x = Math.max(parseInt(x) || 0, 0);
      var y = Math.max(parseInt(y) || 0, 0);
      
      if (showNS)
      {
        north.setLeft(x-1);
        south.setLeft(x-1);
        north.setHeight(y-gap);
        south.setTop(y+gap);
      }
      if (showEW)
      {
        east.setTop(y-1);
        west.setTop(y-1);
        east.setLeft(x+gap);
        west.setWidth(x-gap);
      }
    };
    function show()
    {
      toggleNS(true);
      toggleEW(true);
    };
    function hide()
    {
      toggleNS(false);
      toggleEW(false);
    };
    
    
    //Track the mouse
    body.on('mousemove', function(event)
    {
      if (mouse.drag)
      {
        if (dragMode == 'zoom' || dragMode == 'scale')
        {
          toggleNS(false);
          toggleEW(false);
          return;
        }
      }
      //FIXME: fix this up later
      toggleNS(true);
      //toggleEW(false);
      setXY(mouse.x, mouse.y);
    });
        
    return {
      setGap   : setGap,
      toggleNS : toggleNS,
      toggleEW : toggleEW,
      setXY   : setXY,
      show : show,
      hide : hide
    };
  })();
    
  //Shows a region being selected by the user (click and drag)
  this.Region = (function()
  {
    var ext = Ext.get(document.createElement('DIV'));
    ext.addCls('AJ_region_indicator');
    ext.appendTo(body);
    ext.setDisplayed(false);
    var track = false;
    function show()
    {
      ext.setDisplayed(true);
    };
    function hide()
    {
      ext.setDisplayed(false);
    };
    function setBox(box)
    {
      ext.setLeft(box.x1);
      ext.setTop(box.y1);
      ext.setWidth(box.x2 - box.x1);
      ext.setHeight(box.y2 - box.y1);
    };
    function getBox()
    {
      return {
        x1 : ext.getLeft(true),
        x2 : ext.getLeft(true) + ext.getWidth(),
        y1 : ext.getTop(true),
        y2 : ext.getTop(true) + ext.getHeight()
      };
    };
    function setTrack(t)
    {
        track = t;
    };
    function getTrack()
    {
        return track;
    };
    function mouse2box()
    {
      var x1 = mouse.downX;
      var x2 = mouse.x;
      var y1 = mouse.downY;
      var y2 = mouse.y;
      
      if (x1 > x2)
      {
        var temp = x1;
        x1 = x2;
        x2 = temp;
      }
      if (y1 > y2)
      {
        var temp = y1;
        y1 = y2;
        y2 = temp;
      }
      return {
        x1 : x1,
        x2 : x2,
        y1 : y1,
        y2 : y2
      };
    };
    
//START MOUSE LISTENERS

    //START DRAG EVENT
    self.on('dragStarted', function()
    {
      if (dragMode == 'zoom'){      
          setBox({
            x1 : mouse.downX,
            y1 : mouse.downY,
            x2 : mouse.downX,
            y2 : mouse.downY
          });
          show();
        }
        if(dragMode == 'select'){
            trackHit = self.tracks.mouse2track(mouse.downX+body.getX(),mouse.downY+body.getY());
            if(trackHit){
                setTrack(trackHit);
                setBox({
                x1 : mouse.downX,
                y1 : trackHit.ext.getY()+body.getY(),
                x2 : mouse.downX,
                y2 : trackHit.ext.getY()+body.getY()+trackHit.ext.getHeight()
              });
              trackHit.fireEvent("selectStart");
              show();
            }
        }
      
    });
    
    //STOP DRAG EVENT
    self.on('dragEnded', function()
    {
      var box = getBox();
      
      if (dragMode == 'browse')
      {
        hide();
        self.tracks.each(function(track)
        {
          track.moveCanvas(0);
        });
        location.position+=AnnoJ.pixels2bases(mouse.downX - mouse.x)
        self.fireEvent('browse', location)
      }
      if (dragMode == 'zoom')
      {
        var left = ext.getLeft(true);
        var width = ext.getWidth();
        hide();
        if (width < 10) return;
        location.position = AnnoJ.xpos2gpos(Math.round((box.x1 + box.x2) / 2));
        location.bases = AnnoJ.pixels2bases(box.x2 - box.x1);
        location.pixels = body.getWidth();
        self.fireEvent('browse', location)
      }
      if (dragMode == 'select')
      {
        if(!getTrack()) return;
        var left = ext.getLeft(true);
        var width = ext.getWidth();
        var baseOffset = location.position - (AnnoJ.pixels2bases(body.getWidth()/2));
        var startBase = (AnnoJ.pixels2bases(left) + baseOffset);
        var endBase = (AnnoJ.pixels2bases(left+width) + baseOffset);
        var selectedTrack = getTrack();
        trackHit.fireEvent("selectEnd", startBase, endBase);
        setTrack(false);
        hide();
      }
    });
    
    //CONTINUE DRAG EVENT
    self.on('dragged', function()
    {
      var box = mouse2box();
      
      if (dragMode == 'browse')
      {
        hide();
        ext.setLeft(mouse.x - mouse.downX);
        self.tracks.each(function(track)
        {
          track.moveCanvas(mouse.x - mouse.downX);
        });
        return;
      }
      if (dragMode == 'zoom')
      {
        box.y1 = 0;
        box.y2 = body.getHeight();
        setBox(box);
        return;
      }
      if (dragMode == 'select')
      {         
            if(t = getTrack()){
                box.y1 = t.ext.getY() - body.getY();
                box.y2 = t.ext.getY() + trackHit.ext.getHeight() - body.getY();
                setBox(box); 
            }           
        return;
      }
    });
    //CANCEL DRAG EVENT
    self.on('dragCancelled', function()
    {
        if(dragMode == 'select')
        {
            setTrack(false);
        }
        setBox({
        x1 : 0,
        y1 : 0,
        x2 : 0,
        y2 : 0
      });
      hide();
      
    });
// END MOUSE LISTENERS

    return {
      hide : hide,
      show : show,
      setBox : setBox,
      getBox : getBox
    };
  })();

  this.tracks = (function()
  {   
    var active = [];
    var tracks = [];
    var enabled = [];
    var disabled = [];
    var timer = null;
    var focused = null;

    //Add global listeners
    // Ext.EventManager.addListener(body.dom, 'scroll', function()
    // {
    //   clearTimeout(timer);
    //   timer = setTimeout(refresh, 100);
    // });
    // Ext.EventManager.addListener(window, 'resize', function()
    // {
    //   clearTimeout(timer);
    //   timer = setTimeout(refresh, 100);
    // });

    function doLayout()
    {
      Ext.each(active, function(track)
      {
        //track.Toolbar.toolbar.doLayout();
        track.doLayout();
      });
    };
    
    //Refresh the list of enabled / disabled tracks
    function refresh()
    {
      // clearTimeout(timer);
      // var view = getLocation();
      // disabled = [];
      // enabled = [];
      // 
      // Ext.each(active, function(track)
      // {
      // //         // if (onscreen(track))
      // //         // {
      // //         //  if (track.Syndicator.isSyndicated()) track.unmaskFrame();
      // //         //  enabled.push(track);
      // //         // }
      // //         // else
      // //         // {
      // //         //  track.maskFrame('Track temporarily disabled');
      // //         //  disabled.push(track);
      // //         // }
      // //  //track.unmaskFrame();
      //   enabled.push(track);
      //   track.setLocation(view);
      // });
      self.fireEvent("refresh")
    };
    
    // //Determine whether or not a track is visible to the user
    // function onscreen(track)
    // {
    //  if (body.getTop() > track.ext.getBottom()) return false;
    //  if (body.getBottom() < track.ext.getTop()) return false;
    //  return true;
    // };
    
    //Place a track under management of this object
    function manage(track)
    {
      if (!track instanceof Sv.tracks.BaseTrack) return;
      if (isManaged(track)) return;
      tracks.push(track);
      
      //Attach listeners to the track
      //track.on('generic', propagate);
      track.on('close', close);
      track.on('browse', setLocation);
      track.on('error', error);
      track.on('cancelDrag', cancelDrag);
    };
    
    //Remove a track from management by this object
    function unmanage(track)
    {
      if (!track instanceof AnnoJ.Track) return;    
      close(track);
      tracks.remove(track);
      
      //Remove track listeners
      track.un('generic', propagate);
      track.un('close', close);
      track.un('browse', setLocation);
      track.un('error', error);
      track.un('cancelDrag', cancelDrag);
    };
    
    //Determine whether or not a track is managed
    function isManaged(track)
    {
      return tracks.search(track) != -1;
    };
    
    //Determine whether or not a track is intersected by a mouse event
    function mouse2track(x,y)
    {
      var track = null;
      Ext.each(active, function(item)
      {
        var x1 = item.getX();
        var x2 = x1 + item.getWidth();
        var y1 = item.getY();
        var y2 = y1 + item.getHeight();
        if (x >= x1 && x <= x2 && y >= y1 && y <= y2)
        {
          track = item;
          return false;
        }
      });
      return track;
    };
    
    //Determine whether or not a track is active
    function isActive(track)
    {
      return active.search(track) != -1;
    };
    
    //Add a track to the active display, activating the track in the process
    function open(track, existing)
    {
      if (!isManaged(track)) return;
      if (isActive(track)) return;
      active.push(track);
      
      if (existing)
      {
        track.insertFrameBefore(existing.ext);
      }
      else
      {
        track.appendFrameTo(body.dom);
      }

      track.open();

      refresh();
    };
        
    //Cancel the drag event, this is fired from within a track
    function cancelDrag()
    {
        mouse.drag = false;
        self.fireEvent("dragCancelled");
    }
    //Remove a track from the active display, deactivating the track in the process
    function close(track)
    {
      if (!isActive(track)) return;
      active.remove(track);
      enabled.remove(track);
      disabled.remove(track);
      track.close();    
      refresh();
    };    

    //Reorder a track within the active display
    function reorder(track, existing)
    {
      //if (track.isLocked()) return;
      //track.remove();
      
      if (existing)
      {
        track.insertFrameBefore(existing.ext);
      }
      else
      {
        track.appendFrameTo(body.dom);
      }
      refresh();
    };
    
    //Remove all tracks from the active display
    function closeAll()
    {
      Ext.each(active, close);
    };
        
    
    //Deal with an error that arises from a track
    function error(track, message)
    {
      AnnoJ.error('An error was generated by track: ' + track.name + '.<br />The track has been removed from the display.<br />Error: ' + message);
      close(track);
    };
    
    // Un-used
    // //Propagate a message to all active and visible tracks
    // function propagate(type, data)
    // {
    //  Ext.each(enabled, function(item) {
    //    item.receive(type, data);
    //  });
    // };
    
    //Instruct all active tracks to update position
    function setLocation(view)
    {
      location = view;
      Ext.each(active, function(track)
      {
        track.setLocation(view);
      });
    };
    
    function getLocation()
    {
      return location;
    };
  
    //Clear out entire object
    function clear()
    {
      while (tracks.length) unmanage(tracks[0]);
    };
    
    //Find a track by the specified paramater
    function find(param, value)
    {
      var hit = null;
      Ext.each(tracks, function(track)
      {
        if (track[param] && track[param] == value)
        {
          hit = track;
          return false;
        }
      });
      return hit;
    };
    
    //Get a list of all track configs
    function getConfigs()
    {
      var list = [];
      
      Ext.each(tracks, function(track)
      {
        if(track.id && track.name && track.data && isActive(track)){
          list.push(track.getConfig()); 
        }
      });
      return list;
    };
    
    //Apply a function to all active tracks
    function each(func)
    {
      Ext.each(active, func);
    };
            
    return {
      manage : manage,
      unmanage : unmanage,
      isActive : isActive,
      clear : clear,
      setLocation : setLocation,
      getLocation : getLocation,
      open : open,
      close : close,
      reorder : reorder,
      body : body,
      find : find,
      tracks : tracks,
      active  : active,
      getConfigs : getConfigs,
      closeAll : closeAll,
      each : each,
      mouse2track : mouse2track,
      doLayout : doLayout
    };
  })();
};
Ext.extend(AnnoJ.Tracks,Ext.Panel,{})
