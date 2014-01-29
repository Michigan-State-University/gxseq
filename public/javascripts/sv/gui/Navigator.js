//The navigator wraps an Ext Toolbar and provides genome navigation functionality
AnnoJ.Navigator = function()
{
  var self = this;
  
  //Add custom events
  this.addEvents({
   'browse' : true,
   'describe' : true,
   'dragModeSet' : true
  });

  //Object for syndicating the genome
  var Syndicator = (function()
  {
    var syndication = {};
    
    function syndicate(params)
    {
      if (!params.url) {
        if (params.failure) params.failure('Unable to syndicate as no URL was provided');
        return;
      }
      BaseJS.syndicate({
        url : params.url,
        bioentry : params.bioentry,
        success : function(response)
        {
          syndication = response;
          //Controls.setTitle(syndication.service.title);
          
          if (syndication.bioentry)
          {
            //Controls.bindAssemblies(syndication.genome.assemblies);
          }
          if (params.success)
          {           
            ////Build the Sequence selectors
            
            //Species
            var species_menu = new Ext.menu.Menu({title : 'Species'});
            Ext.each(syndication.species.data, function(item){
              species_menu.add({
                text      : item.name,          
                link_id   : item.id,  
                handler : function(item,event){
                  window.location=syndication.service.entry_url+"/"+item.link_id
                }
              });
            })
            var species = new Ext.button.Split({
              tooltip : 'Select Organism',
              text  : syndication.species.selected,
              menu : species_menu
            });
            
            //Strain - Sub Taxon
            var taxon_menu = new Ext.menu.Menu({title : 'Strain'});
            Ext.each(syndication.taxons.data, function(item){
              taxon_menu.add({
                text      : item.name,          
                link_id   : item.id,  
                handler : function(item,event){
                  window.location=syndication.service.entry_url+"/"+item.link_id
                }
              });
            })
            var taxon = new Ext.button.Split({
              tooltip: "Select Strain",
              text : syndication.taxons.selected,
              menu : taxon_menu
            });
            
            // Version
            var version_menu = new Ext.menu.Menu({title : 'Version'});
            Ext.each(syndication.versions.data, function(item){
              version_menu.add({
                text      : item.name,          
                link_id   : item.id,  
                handler : function(item,event){
                  window.location=syndication.service.entry_url+"/"+item.link_id
                }
              });
            })            
            var version = new Ext.button.Split({
              tooltip: "Select Version",
              text : syndication.versions.selected,
              menu : version_menu
            });
            
            if(syndication.entries.use_search)
            {
              //model
               Ext.define('SequenceSearchResult',{
                 extend : 'Ext.data.Model',
                 fields: [
                 {name: 'id', type:'int'},
                 {name: 'accession', type:'string'},
                 {name: 'name', type:'string'},
                 ]
               });
               //store
               var ds = Ext.create('Ext.data.Store',{
                 model: 'SequenceSearchResult',
                 pageSize : 10,
                 proxy : {
                   type : 'ajax',
                   url : syndication.entries.search_url,
                   reader:{
                     type : 'json',
                     root : 'rows',
                     totalProperty : 'count',
                     id : 'id'
                   },
                   extraParams : {
                     assembly  : syndication.entries.assembly_id
                   }
                 },

               });
               //search box
               var sequence = new Ext.form.ComboBox({
                 store       : ds,
                 valueField  : 'id',
                 width       : 250,
                 queryDelay  : 500,
                 minChars    : 3,
                 pageSize    : 10,
                 hideTrigger : false,
                 emptyText   : syndication.entries.selected,
                 listConfig  : {
                   loadingText  : 'Searching for Sequence...',
                   getInnerTpl: function() {
                     return '<div class="drop_list"><div style="float:left"><b>{name}</b></div><div style="float:right">{accession}</div><br/></div>'
                   },
                   height: 500
                 },     
                 listeners : {
                   beforequery:function(queryEvent){
                     //Hack fix for missing query param: http://www.sencha.com/forum/showthread.php?134592-EXTJSIV-2470-4.0.1-ComboBox-not-issuing-queryParam-on-paging-requests
                     queryEvent.combo.store.proxy.extraParams.query = queryEvent.combo.getValue();
                   },
                   change:function(combo){
                     combo.store.currentPage = 1;
                   },
                   select : function(box, items)
                   {
                     record = items[0] //we only use single selection
                     window.location = (syndication.service.entry_url+"/"+record.data.id+'?'+AnnoJ.activeTrackParams())
                   }
                 }
               });
            }else{
              //drop down menu if we have more than 1
              if(syndication.entries.length > 1)
              {
                var sequence_menu = new Ext.menu.Menu({title : 'Sequence', maxHeight : 400});
                var accession = new Ext.Toolbar.TextItem()
                Ext.each(syndication.entries.data, function(item){
                 sequence_menu.add({
                   text      : item.name,          
                   link_id   : item.id,  
                   handler : function(item,event){
                     window.location=syndication.service.entry_url+"/"+item.link_id
                   }
                 });
                })
                //if(syndication.entries.data.length >= 15) sequence_menu.add({text : ' '}); //bug in scroll window. Partially hides last element
                var sequence = new Ext.button.Split({
                 tooltip: "Select Sequence",
                 text : syndication.entries.selected,
                 menu : sequence_menu
                });
              }
              //text if only 1
              else{
                var sequence = new Ext.Toolbar.TextItem()
                sequence.setText(syndication.entries.selected)
              }
            }
            
            //External Accession Link
            var accession = new Ext.Toolbar.TextItem()
            if(syndication.entry.accession && syndication.entry.accession_link)
            {
              accession.setText("<a href='"+syndication.entry.accession_link+"' target='"+syndication.entry.accession+"'>"+syndication.entry.accession+"</a>")
            }else if(syndication.entry.accession){
              accession.setText(syndication.entry.accession)
            }
            
            // Put It all together into a toolbar
            var titleBar = new Ext.Toolbar(
            {
              height: 26,
              cls : 'x-panel-header',
              items: [
                species,
                "-",
                taxon,
                "-",
                version,
                "-",
                sequence,
                "->",
                accession,
              ] 
            })
            // Place the toolbar in UI
            navContainer.insert(0,titleBar);
            // Initialize the UI
            Navigator.Position.init({
              min : 1,
              max : syndication.entry.size,
            });
            
            //AnnoJ.getGUI().Tracks.doLayout();
            AnnoJ.getGUI().Tracks.doComponentLayout();
            params.success(response);
          }
        },
        failure : function(string)
        {
          if (params.failure) params.failure(string);
        }
      });
    };
    
    function get()
    {
      return syndication;
    };
    
    return {
      get : get,
      syndicate : syndicate
    };
  })();

  //Object for managing the viewing position of the tracks
  var Navigator = (function()
  {
    var location = {
      position : 0,
      bases : 10,
      pixels : 1
    };
    
    //Object for managing position selection
    var Position = (function() {
      
      var defaultConfig = {
        min : 0,
        max : 0,
        position : 0,
        verbose : false,
        padding : 25
      };
      var config = defaultConfig;
      var atMin = false;
      var atMax = false;
      
      //Initialize the position object and ExtJS components
      function init(userConfig)
      {
        Ext.apply(config, userConfig, defaultConfig);
        set(config.position);
        //update the slider component
        //Here because this only should be done once. Where else can we put it?
        self.Controls.slider.setMinValue(config.min);
        self.Controls.slider.setMaxValue(config.max);
        self.Controls.slider.setValue(config.position);
      };
      
      //Get the current position
      function get()
      {
        return config.position;
      };
      
      function max()
      {
        return config.max;
      };
      function min()
      {
        return config.min;
      };
      function config()
      {
        return config;
      };
      //Set the current position
      function set(gpos)
      {
        //Check the position for validity
        var gpos = parseInt(gpos || 1);
        
        atMin = false;
        atMax = false;
        
        // Check boundaries
        width = Toolbar.getBox().width
        halfX = Math.round(width/2);
        ratio = Zoom.config.bases / Zoom.config.pixels;
        offset = Math.round((halfX-config.padding)*ratio);
        if(offset<0)offset=0;        
        
        if (gpos > (config.max-offset))
        {
          gpos = (config.max-offset);
          atMax = true;
        }
        
        if (gpos < (config.min+offset))
        {
          gpos = (config.min+offset);
          atMin = true;
        }

        config.position = gpos;
        location.position = gpos;
      };
      
      return {
        init : init,
        get : get,
        set : set,
        max : max,
        min : min,
        config: config,
        atMax : function() { return atMax; },
        atMin : function() { return atMin; }
      };
    })();
    
    //Object for managing the zoom selection
    var Zoom = (function()
    {
      
      var defaultConfig = {
        max : 100000,
        min : 0.05,
        bases : 10,
        pixels : 1,
        verbose : false
      };
      var config = defaultConfig;
      var lastConfig = {};
      var atMin = false;
      var atMax = false;
      
      //Initialize the zoom object
      function init(userConfig)
      {
        Ext.apply(config, userConfig, defaultConfig);
        set(config.bases, config.pixels);
      };
      
      //Scale the zoom ratio by a defined amount
      function scale(multiplier)
      {
        if (!multiplier) return;
  
        var bases  = multiplier > 0 ? config.bases * multiplier : config.bases;
        var pixels = multiplier > 0 ? config.pixels             : config.pixels * -multiplier;
  
        set(bases, pixels);
      };
      
      //Zoom in or out by a fixed amount determined by the current level
      function step(closer)
      {
        var b = config.bases;
        var p = config.pixels;
        
        if (b > p)
        {
          var f = Math.pow(10, Math.round((b+'').length)-1);
          var d = b / f;
          
          if (closer)
          {
            b = (d == 1) ? b - f/10 : b - f;
          }
          else
          {
            b = b + f;
          }
        }
        else if (b < p)
        {
          var f = Math.pow(10, Math.round((p+'').length)-1);
          var d = p / f;

          if (closer)
          {
            p = p + f;
          }
          else
          {
            p = (d == 1) ? p - f/10 : p - f;
          }
        }
        else
        {
          closer ? p++ : b++;
        }
        set(b,p);
      };
      
      function get()
      {
        return {
          bases : config.bases,
          pixels : config.pixels
        };
      };
      
      function getPrevious()
      {
        return {
          bases : lastConfig.bases,
          pixels : lastConfig.pixels
        }
      }
      //Set a new zoom value
      function set(bases, pixels)
      { 
        //Sanity check
        if (!bases || !parseInt(bases)) bases = 1;
        if (!pixels || !parseInt(pixels)) pixels = 1;
        
        bases = parseInt(bases);
        pixels = parseInt(pixels);
  
        atMin = false;
        atMax = false;
        
        var ratio = bases / pixels;
      
        width = self.Toolbar.getBox().width;
        // Check boundaries
        ceiling = Position.config.max + (2*Position.config.padding*ratio)
        if(ratio*width > ceiling)
        {
          atMax = true;
          //Max zoom for data
          if(ceiling > width){
            bases = Math.ceil(ceiling/width);
            pixels = 1;
          }
          //Max zoom for data shorter than one window
          else{
            bases = 1;
            pixels = Math.floor(width/ceiling);
            if((bases/pixels) < config.min ) pixels = (bases/config.min)
          }
        }
        else if (ratio >= config.max)
        {
          bases = config.max;
          pixels = 1;
          
          if (bases < 1) {
            pixels = Math.round(1/bases);
            bases = 1;
          }
          atMax = true;
        }
        else if (ratio <= config.min)
        {
          bases = 1;
          pixels = Math.round(1/config.min);
          
          if (pixels == 0) {
            bases = Math.round(config.min);
            pixels = 1;
          }
          atMin = true;
        }
        else
        {
          if (bases > pixels)
          {
            bases = Math.round(bases / pixels); 
            pixels = 1;
            var f = Math.pow(10, Math.round((bases+'').length)-1);
            bases = f * Math.round(bases/f);
          }
          else {
            pixels = Math.round(pixels / bases);
            bases = 1;
            var f = Math.pow(10, Math.round((pixels+'').length)-1);
            pixels = f * Math.round(pixels/f);
          }
        }
        
        // store for recall
        if((bases != config.bases) || (pixels != config.pixels)){
          lastConfig.bases = config.bases;
          lastConfig.pixels = config.pixels;
        }
        
        config.bases = bases;
        config.pixels = pixels; 
        location.bases = bases;
        location.pixels = pixels;
      };
      
      return {
        init : init,
        scale : scale,
        step : step,
        set : set,
        get : get,
        getPrevious : getPrevious,
        config : config,
        atMax : function() { return atMax; },
        atMin : function() { return atMin; },
      };
    })();
    
    //Get the current location of the navigator
    function getLocation()
    {
      return location;
    };
    
    //Set the current position of the navigator
    function setLocation(view)
    {
      var view = Ext.apply({}, view || {}, location);
      //Assembly.set(view.assembly);
      Position.set(view.position);
      Zoom.set(view.bases, view.pixels);
      Controls.refreshControls();
      return location;
    };
    
    function step(closer)
    {
      Zoom.step(closer);
    };
    
    //Scale the current zoom level by the specified multiplier
    function scale(multiplier)
    {
      if (!multiplier || !parseFloat(multiplier)) return;
      Zoom.scale(multiplier);
    };
    
    //Bump the current position by the specified number of bases
    function bump(bases)
    {
      if (!bases || !parseInt(bases)) return;
      Position.set(location.position + parseInt(bases));
    };

    //Return the number of bases mapped by the specified pixels
    function pixels2bases(pixels)
    {
      if (!pixels || !parseInt(pixels)) return 0;
      return Math.floor(parseInt(pixels) * location.bases / location.pixels);     
    };
    
    //Return the number of pixels mapped by the specified bases
    function bases2pixels(bases)
    {
      if (!bases || !parseInt(bases)) return 0;
      return Math.round(parseInt(bases) * location.pixels / location.bases);
    };
    
    //Convert an x position to a genome position
    function xpos2gpos(xpos)
    {
      var edges = getEdges();
      return pixels2bases(xpos) + edges.g1;
    };
    
    //Convert a genome position to an x position
    function gpos2xpos(gpos)
    {
      var edges = getEdges();
      return bases2pixels(gpos) - edges.x1;
    };
    
    //Get the edges of the view
    function getEdges()
    {
      var halfX = Math.round(Toolbar.getBox().width/2);
      var halfG = pixels2bases(halfX);
      var locG = location.position;
      var locX = bases2pixels(locG);
      return {
        g1 : locG - halfG,
        g2 : locG + halfG,
        x1 : locX - halfX,
        x2 : locX + halfX
      };
    };
    
    //Get the genome coordinates surrounding value
    function getSides(value)
    {
      var halfX = Math.round(Toolbar.getBox().width/2);
      var halfG = pixels2bases(halfX);
      var locG = value;

      return {
        g1 : locG - halfG,
        g2 : locG + halfG,
      };
    };
    
    return {
      //Assembly : Assembly,
      Position : Position,
      Zoom     : Zoom,
      getLocation : getLocation,
      setLocation : setLocation,
      scale : scale,
      bump  : bump,
      step  : step,
      pixels2bases : pixels2bases,
      bases2pixels : bases2pixels,
      xpos2gpos : xpos2gpos,
      gpos2xpos : gpos2xpos,
      getSides : getSides,
      recallZoom : Zoom.recallZoom
    };
    
  })();
  
  //Build the custom Controls
  var Controls = (function()
  {
    var needsResize = true;
    ////Button for showing information about the genome
    var info = new Ext.Button(
    {
      iconCls : 'silk_information',
      tooltip : 'Show information about the track',
      handler : function()
      {
        self.fireEvent('describe', Syndicator.get());
      }
    });
    
    //Text item for showing the genome name
    var title = Ext.create('Ext.toolbar.TextItem',{text:'Awaiting syndication...'});
    
    //Slider for navigating the genome
    var slider = new Ext.slider.Single({
      cls     : "custom-slider",
      width   : 300,
      useTips: true,
      tipText : function(thumb){
        pos = Navigator.getSides(thumb.value);
        return (pos.g1 < 0) ? 0 : Math.round(pos.g1) +"-"+ Math.round(pos.g2);
           },
      plugins : [Ext.ux.SliderShift]
    });
    
    slider.on('changecomplete', function(slider, newVal, thumb){
      Navigator.setLocation({position : newVal});
      refreshControls();
      self.fireEvent('browse', Navigator.getLocation());
    });
    
    //Split button for choosing the drag mode
    var dragMode = new Ext.CycleButton({
      showText: true,
      prependText: 'Dragmode: ',
      tooltip : 'Action to be performed when you click and drag in a track',
      menu: {
          id: 'drag-mode-menu',
          items: [
          {
            text      : 'browse',
            itemId    : 'browse',
            iconCls   : 'silk_cursor',
            checked   : true
          },{
            text      : 'zoom',
            itemId    : 'zoom',
            iconCls   : 'silk_magnifier'
          },{
            text      : 'scale',
            itemId    : 'scale',
            iconCls   : 'silk_arrow_inout'
          },{
            text      : 'resize',
            itemId    : 'resize',
            iconCls   : 'silk_shape_handles'
          },{
              text        : 'select',
              itemId      : 'select',
              iconCls     : 'silk_select_area'
          }]
      },
      changeHandler : function(btn, item)
      {
        self.fireEvent('dragModeSet', item.text);
      }
    });
    Ext.EventManager.addListener(window, 'keyup', function(event)
    {
        // if (event.getTarget().tagName == 'INPUT') return;
        // if (event.getKey() != 16) return; //Shift Key
        // dragMode.toggleSelected();
    });
    function setDragMode(mode)
    {
      Controls.dragMode.menu.getComponent(mode).setChecked(true);
    };

    //Text box for manually setting the zoom ratio
    var ratio = new Ext.form.TextField(
    {
      width         : 55,
      maskRe        : /[0-9:]/,
      regex         : /^[0-9]+:[0-9]+$/,
      selectOnFocus : true
    });
    ratio.on('blur', function(config, event)
    {
      var value  = this.getValue() || '10:1';
      var bases  = parseInt(value.split(':')[0]);
      var pixels = parseInt(value.split(':')[1]);
      
      var curLocation = Navigator.getLocation();
      var location = Navigator.setLocation(
      {
        position: curLocation.position,
        bases : bases,
        pixels : pixels
      });
      refreshControls();
      self.fireEvent('browse', Navigator.getLocation());
    });
    ratio.on('specialKey', function(config, event)
    {
      if (event.getKey() == event.ENTER)
      {
        this.fireEvent('blur');
        document.activeElement.blur();
      }
    });
    
    //Button for zooming out
    var further = new Ext.Button(
    {
      iconCls : 'silk_zoom_out',
      tooltip : 'Zoom out by a fixed increment',
      handler : function()
      {
        if (this.disabled) return;
        Navigator.step(false);
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
      }
    });
    
    //Button for zooming in
    var closer = new Ext.Button(
    {
      iconCls : 'silk_zoom_in',
      tooltip : 'Zoom in by a fixed increment',
      handler : function()
      {
        if (this.disabled) return;
        Navigator.step(true);
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
      }
    });
    
    //Text box for setting the position on the currently selected assembly
    var jump = new Ext.form.NumberField(
    { 
      width         : 75,
      allowNegative : false,
      allowDecimals : false,
      enableKeyEvents: true
    });
    jump.on('specialKey', function(config, event)
    {
      if (event.getKey() == event.ENTER)
      {
        Navigator.setLocation(
        {
          position : parseInt(this.getValue())
        });
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
        document.activeElement.blur();
      }
    });
    
    //Go button for the position elements
    var go = new Ext.Button(
    {
      iconCls : 'silk_server_go',
      text    : 'Go',
      tooltip : 'Browse to the specified position',
      handler : function()
      {
        Navigator.setLocation(
        {
          position : parseInt(jump.getValue())
        });
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
      }
    });
    
    //Button to jump to the previous screen
    var prev = new Ext.Button(
    {
      iconCls : 'silk_arrow_left',
      tooltip : 'Jump one screen to the left',
      handler : function()
      {
        Navigator.bump(-Navigator.pixels2bases(Toolbar.getSize().width));
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
      }
    });
    
    //Button to jump to the next screen
    var next = new Ext.Button(
    {
      iconCls : 'silk_arrow_right',
      tooltip : 'Jump one screen to the right',
      handler : function()
      {
        Navigator.bump(Navigator.pixels2bases(Toolbar.getSize().width));
        refreshControls();
        self.fireEvent('browse', Navigator.getLocation());
      }
    });
    
    // revert to the last used zoom level
    function recallZoom() {
      Navigator.setLocation(Navigator.Zoom.getPrevious());
      refreshControls();
      self.fireEvent('browse', Navigator.getLocation());
    };
    
    //Update GUI Controls to match the state of the Navigator object
    function refreshControls()
    {
      var view = Navigator.getLocation();
      
      //Update zoom components
      closer.enable();
      further.enable();
      
      if (Navigator.Zoom.atMin()) closer.disable();
      if (Navigator.Zoom.atMax()) further.disable();
      
      ratio.setValue(view.bases + ':' + view.pixels);
  
      //Update position components
      prev.enable();
      next.enable();
      
      if (Navigator.Position.atMin()) prev.disable();
      if (Navigator.Position.atMax()) next.disable();
      
      jump.setValue(view.position);

      //Update slider component
      updateSlider();
    };
    
    function updateSlider() {
      var view = Navigator.getLocation();
      //Get widths
      var tbItemWidth = 0
      var sw = slider.el ? slider.getWidth() : 100;
      Toolbar.items.each(function(item,idx,total){
        if(!item.el) return true;
        tbItemWidth += item.getWidth();
      });
      tbItemWidth+=60; //extra padding

      // set slider width
      newSliderWidth = self.Toolbar.getWidth()-(tbItemWidth-sw)
      if(newSliderWidth < 100) newSliderWidth=100;
      slider.setWidth(newSliderWidth)
      //set thumb width
      if(slider.thumbs[0].el){
          var basesPerPixel = Navigator.Zoom.config.bases / Navigator.Zoom.config.pixels;  
          bar_ratio = (basesPerPixel*self.Toolbar.getBox().width) / (Navigator.Position.config.max + (2*Navigator.Position.config.padding*basesPerPixel))
          var newWidth = Math.max(Math.floor(bar_ratio * slider.getWidth()),20)
          var e = slider.thumbs[0].el
          e.setWidth(newWidth+"px");
          slider.halfThumb = Math.floor(newWidth / 2);
      }
      slider.setValue(view.position);
    };
    
    return {
      info     : info,
      slider    : slider,
      dragMode  : dragMode,
      ratio     : ratio,
      further   : further,
      closer    : closer,
      jump      : jump,
      go        : go,
      prev      : prev,
      next      : next,
      refreshControls : refreshControls,
      updateSlider : updateSlider,
      setDragMode     : setDragMode,
      needsResize : needsResize,
      recallZoom : recallZoom
    };
    
  })();
  
  
  //Instantiate the wrapped component
  var Toolbar = new Ext.Toolbar(
  {
    cls   : 'AJ_Navbar',
    items : [ 
      Controls.slider,
      {xtype: 'tbspacer', width: 10},
      '-',
      ' ',
      Controls.dragMode,
      '-',
      Controls.ratio,
      Controls.further,
      Controls.closer,
      '-',
      'Position:',
      Controls.jump,
      Controls.go,
      '-',
      Controls.prev,
      Controls.next
    ]
  });
  
  Toolbar.on('render', function()
  {
   //add handlers
   //add Controls
   this.un('render');
   Controls.refreshControls();
  });
  
  //listen for resize event to update slider component width
  Toolbar.on('resize',function(){
      Controls.updateSlider();
  })
  
  var navContainer = new Ext.Container({
    layout: 'anchor',
    dock: 'top',
    items:[
      //titleBar, //will be inserted after syndication
      Toolbar
    ]
  });
  
  this.Toolbar = Toolbar;
  this.ext = navContainer;
  this.getLocation  = Navigator.getLocation;
  this.setLocation  = Navigator.setLocation;
  this.pixels2bases = Navigator.pixels2bases;
  this.bases2pixels = Navigator.bases2pixels;
  this.xpos2gpos = Navigator.xpos2gpos;
  this.gpos2xpos = Navigator.gpos2xpos;
  this.syndicate = Syndicator.syndicate;
  this.setTitle  = Controls.setTitle;
  this.setDragMode = Controls.setDragMode;
  this.Controls = Controls;
  this.recallZoom = Controls.recallZoom;
};

//Provide observability
Ext.extend(AnnoJ.Navigator,Ext.util.Observable,{})
