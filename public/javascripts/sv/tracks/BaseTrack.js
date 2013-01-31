//Core track
Ext.define("Sv.tracks.BaseTrack",{
    extend : 'Ext.Component',
    mixes:{
        observable: 'Ext.util.Observable'
    },
    //id           : Ext.id(),
	name         : 'Track',
	path         : '',
	datasource   : '',
	minHeight    : 40,
	maxHeight    : 1000,
	height       : 40,
	showControls : true,
	cls          : 'AJ_track',
	iconCls      : 'silk_bricks',
	enableMenu   : true,
	initComponent : function(){
	    this.callParent(arguments);
        var self = this;
        //Add events
         self.addEvents({
             'generic'       : true,
             'close'         : true,
             'error'         : true,
             'resize'        : true,
             'selectStart'   : true,
             'selectEnd'     : true,
             'cancelDrag'    : true
         });
             
         // cancel the select event; remove with this.removeListener
         // the select event is fired from the 'select' mouseMode
         this.cancelSelectStart = function(){
                self.fireEvent('cancelDrag');
         };
         this.on("selectStart", this.cancelSelectStart);
             
         //Object that contains the track and is resizable (if configured to be)
         this.Frame = (function()
         {
             var ext = Ext.get(document.createElement('DIV'));

             ext.addCls('AJ_track');
             ext.addCls(self.cls);
    
             //Override the context menu
             ext.on('contextmenu', function(event)
             {
                 event.stopEvent();
                 if (self.enableMenu)
                 {
                     self.contextMenu.ext.showAt([event.getPageX(), event.getPageY()]);
                 }
    
                 return false;
             });
    
             //Set the height
             ext.setHeight(self.height);
    
             return {
                 ext : ext
             };
         })();
        
        
         //Provides overflow for track content (has to be this way to satisfy resizability of frame)
         this.Overflow = (function()
         {
             var ext = Ext.get(document.createElement('DIV'));
             ext.addCls('AJ_overflow');
             return {
                 ext : ext
             };
         })();
    
         //Provides a static container for the rendering area. Overflow acts as a viewport.
         this.Canvas = (function()
         {
             var ext = Ext.get(document.createElement('DIV'));
             ext.addCls('AJ_canvas');
             return {
                 ext : ext
             };      
         })();

        //Context menu for the track
        this.contextMenu = (function()
        {
         var ext = new Ext.menu.Menu();
        
         // function enable()
         // {
         //     self.enableMenu = true;
         // };
         //         
         // function disable()
         // {
         //     self.enableMenu = false;
         // };
        
         function addItems(items)
         {
             Ext.each(items, function(item)
             {
                 ext.add(item);
             });
         };
        
         // function get(item)
         // {
         // };
        
         return {
             ext : ext,
             //enable : enable,
             //disable : disable,
             addItems : addItems,
             //get : get
         };
        })();

        //Object for controlling the track's toolbar
        this.Toolbar = (function()
        {
         var ext = new Ext.Element(document.createElement('DIV'));
         ext.addCls('AJ_toolbar');
         ext.appendTo(document.body);
        
         visible = self.showControls;
        
         var toolbar = new Ext.Toolbar({
             renderTo : ext,//self.Frame.ext,
             height: 25
         });
         //ext.appendChild(toolbar);
         
         //Button to close (remove) the track
         var closeButton = new Ext.Button(
         {
             iconCls : 'silk_delete',
             tooltip : 'Remove the track',
             permanent : true,
             //handleMouseEvents : false,
             handler : function() {
               //Manually remove the hover button style before closing
               this.removeClsWithUI(this.overCls);
               self.fireEvent('close', self);
             }
         });
        
        // Commented out for now till other permission features
        // are all worked out

        var addButton = ' ';
        // if(self.config.showAdd){
        //   addButton = new Ext.Button(
        //      {
        //        iconCls : 'silk_add',
        //        tooltip : 'Add data',
        //        permanent : true,
        //        handler : function() {
        //          track.fireEvent('new_item');
        //        }
        //      });
        // }
                    
                    //Shows the title of the track
         var title = new Ext.Toolbar.TextItem(self.config.name);
         title.permanent = true;
         //Ext.get(title.getEl()).addCls('AJ_track_title');
         title.addCls('AJ_track_title')
         //Filler to fill in space
         var filler = Ext.create('Ext.Toolbar.Fill');
         filler.permanent = true;
                         
         //Control to toggle the toolbar on and off
             
         var toggleButton = new Ext.Button(
         {
             iconCls : 'silk_application',
             tooltip : 'Toggles toolbar visibility',
             handler : toggle,
             permanent : true
         });
             
         var spacer = new Ext.Toolbar.Spacer();
         spacer.permanent = true;
         
         var items = [closeButton,addButton, title, filler, toggleButton, spacer];
         toolbar.add(items);          
                      
         //Change the title shown in the toolbar
         function setTitle(text)
         {
             //Ext.get(title.getEl()).update(text);
             title.setText(text);
             toolbar.doLayout();
         };
         function getTitle()
         {
             //return title.getEl().innerHTML;
             if (title.rendered) {
                 return title.el.dom.innerHTML;
             } else {
                 return title.autoEl.html;
             }
         };
                     
         //Toggle the toolbar on or off (not as simple as just calling toolbar.hide()).
         function toggle()
         {
             visible ? hide() : show();
         };
         function show()
         {
             visible = true;
                 
             Ext.each(items, function(item)
             {
                 if (item.show) item.show();
             });
         };
         function hide()
         {
             visible = false;
        
             Ext.each(items, function(item)
             {
                 if (item.hide && !item.permanent) item.hide();
             });
         };
             
         //Add an item to the toolbar
         function insert(index, item)
         {
             if (!item.show || !item.hide) return;
             items.insert(index, item);
             // we have to queue up the insert or EXT tries to manipulate the dom
             // when the dom item doesn't exist yet...
             //toolbar.insert(index, item);
             toolbar.on('enable', function(){
               this.insert(index,item);
             },
             toolbar,
             {
               single : true
             });
         };
             
         function isVisible()
         {
             return visible;
         };
             
         //Ext.removeNode(ext);
             
         return {
             ext : ext,
             toolbar   : toolbar,
             setTitle  : setTitle,
             getTitle  : getTitle,
             toggle    : toggle,
             show      : show,
             hide      : hide,
             insert    : insert,
             isVisible : isVisible
         };
        })();
        
        //Assemble the structural elements
        this.Frame.ext.appendChild(this.Toolbar.ext);
        this.Frame.ext.appendChild(this.Overflow.ext);
        this.Overflow.ext.appendChild(this.Canvas.ext);
        this.ext = this.Frame.ext;
	},
    //Functions for interacting with the DOM
    appendFrameTo      : function(d) { this.Frame.ext.appendTo(d);this.Toolbar.toolbar.enable()},
    removeFrame      : function()  { 
			if(this.Frame.ext.dom.parentNode){this.Frame.ext.dom.parentNode.removeChild(this.Frame.ext.dom)}
		},//Ext.removeNode(self.Frame.ext.dom);};
    insertFrameBefore  : function(d) { this.Frame.ext.insertBefore(d);this.Toolbar.toolbar.enable()},
    insertFrameAfter   : function(d) { this.Frame.ext.insertAfter(d);},
    maskFrame          : function(m) { this.Frame.ext.mask(m); },
    unmaskFrame        : function()  { this.Frame.ext.unmask(); },
    isFrameMasked      : function()  { return this.Frame.ext.isMasked(); },   
    //Set the title of the track
    getTitle : function()      { return this.Toolbar.getTitle(); },
    setTitle : function(title) { this.Toolbar.setTitle(title);},
    //Control the width and height of the track
    getX      : function()  { 
      return this.Frame.ext.getX();
    },
    getY      : function() { return this.Frame.ext.getY();},
    getWidth  : function()    { return this.Frame.ext.getWidth();  },
    setWidth  : function(w) { this.Frame.ext.setWidth(w);         },
    getHeight : function()  { return this.Frame.ext.getHeight(); },
    setHeight : function(h) {this.Frame.ext.setHeight(h);},
    getMinHeight : function() { return this.minHeight; },
    getMaxHeight : function() { return this.maxHeight; },
    doLayout : function() { this.Toolbar.toolbar.doLayout();}
    // //Generic event handling
    // broadcast : function(type, data){
    //  this.fireEvent('generic', type, data);
    // },
    // receive : function(type, data){}
});