//Track Selector component
Ext.define('Sv.gui.TrackSelector',{
  extend:       'Ext.tree.TreePanel',
  title:          'Track Selection',
  iconCls:        'silk_application_side_tree',
  viewConfig: {plugins: {ptype: 'treeviewdragdrop'}},
  border:         false,
  autoScroll:     true,
  rootVisible:    false,
  singleExpand:   false,
  hideCollapseTool: true,
  //minWidth: 1000,
  lines: false,
  activeTracks:   [],
  rootVisible: false,
  hideHeaders: false,
  columns: [{
      text: '',
      dataIndex: 'text'
      ,editor: {
          allowBlank: false
          ,xtype: 'textfield'
      }
      ,flex:1
      ,sortable: false
      ,xtype: 'treecolumn'  //REQUIRED
  }],
  plugins:[{
    pluginId: 'edit-plug',
    ptype: 'treeediting',
    clicksToEdit: 2,
    listeners:{
      beforeedit:{
        fn: function(obj){
          if(!obj.record.data.editable==true){return false;}
        }
      },
      edit:{
        fn: function(plugin, obj){
          //return unless finished
          if(obj.record.editing) return;          
          var editNode = obj.record;
          var newValue = obj.value;
          if(newValue!=obj.originalValue){
            //update inactive children
            Ext.each(editNode.childNodes, function(){
              this.updatePath(newValue);
            });
            //update active children
            Ext.each(obj.grid.active.childNodes, function(child){
              if(child.originalParent == editNode){
                child.updatePath(newValue);
              }
            });
          }
        }
      }
    }
  }],
  root: {
    text: 'root',
    expanded: true,
    allowDrag:false,
    allowDrop:false,
    children: [
    {text: 'active',children:[],expanded:true,allowDrag:false,allowDrop:true}, {text: 'inactive',children:[],expanded:true,allowDrag:false,allowDrop:true}
    ]
  },
  initComponent: function(){
    arguments['root']=this.root;
    this.callParent(arguments);
    var self = this;
    
    //Add custom events
    self.addEvents({
      'openTrack'  : true,
      'closeTrack' : true,
      'moveTrack'  : true
    });
    
    // Add Track Browser
    self.trackBrowser = Ext.create('Sv.gui.TrackBrowser',{
      trackManager: self.trackManager
    })
    // Handle Track Browser events
    self.trackBrowser.on('removeTrack',function(track){
      self.inactive.appendChild(track.node);
    })
    self.trackBrowser.on('insertTrack',function(track,index){
      self.active.insertChild(index,track.node);
    })
    self.trackBrowser.on('openTrack',function(track){
      self.activate(track);
    })
    self.trackBrowser.on('closeTrack',function(track){
      self.inactivate(track);
    })
    // Setup toolbar icons
    self.tools = [{
      id:'save',
      qtip: 'Save layout',
      handler: function(event, toolEl, panel){
        self.showLayoutForm();
      }
    },
    {
      id:'plus',
      qtip: 'New folder',
      handler: function(){
        self.expand();
        node = self.createNewNode("New Folder");
        node = self.inactive.appendChild(node);
        self.plugins[0].startEdit(node, self.columns[0])
      }
    },
    {
      id:'search',
      qtip: 'Track Browser',
      handler: function(){    
        self.trackBrowser.show();
      }
    }];

    //root tree node
    var root = self.getRootNode();            
    //tree node for active tracks
    self.active = root.childNodes[0]        
    //tree node for inactive tracks
    self.inactive = root.childNodes[1]

    //Item events				
    ////Right Click
    self.on('itemcontextmenu',function(thisView, record, htmlItem, index, event, opts){
      event.stopEvent();
      if(record.isLeaf()){
        if(record.parentNode == self.active)
        record.track.contextMenu.ext.showAt([event.getPageX(), event.getPageY()]);
        else{
          trackMenu.setItem(record);
          trackMenu.ext.showAt([event.getPageX(), event.getPageY()]);
        }
      }
    else if(record != self.active && record != self.inactive)
    {
      folderMenu.setItem(record);
      folderMenu.ext.showAt([event.getPageX(), event.getPageY()]);
    }
    });
    
    ////Double Click
    self.on('itemdblclick',function(thisView, record, htmlItem, index, event, opts){      
      if(record.isLeaf()){
        self.toggle_active(record);
      }
    });
    //Context Menu for tracks (when inactive)
    var trackMenu = (function(){
      var item ;
      function setItem(i)
      { item = i };
      var ext = new Ext.menu.Menu({
        items : [
        'Options',
        '-',                
        {   
          xtype : 'menuitem',
          iconCls : 'silk_add',
          text : "Activate",
          handler : function(){
            self.activate(item.track);
          }
        }
        ]
      });
      return {
        ext : ext,
        setItem : setItem
      };
    })();
    //Context Menu for folders
    var folderMenu = (function(){
      var folder = this.inactive;
      function setItem(i)
      { folder = i };
      var ext = new Ext.menu.Menu({
        items : [
        'Options',
        '-',                
        {   
          xtype : 'menuitem',
          iconCls : 'silk_delete',
          text : "Delete Folder",
          handler : function(){
            self.removeNode(folder);
          }
        }
        ]
      });
      return {
        ext : ext,
        setItem : setItem
        };
      }
    )();
    // Save Layout Form
    var txtField = new Ext.form.TextField({
      fieldLabel: 'Layout Name',
      allowBlank: false
    });
    this.win = new Ext.Window({
      title:'New Layout',
      x: 500, y: 300, width:280, height:110, minWidth:290, minHeight:110,
      layout:'fit', border:false, closable:true,closeAction:"hide",
      items:[{   
        xtype: 'form',
        frame: true,
        items:[txtField],
        pollForChanges: true,
        buttons:[{
          text : "save",
          formBind : true,
          handler : function(){
            self.postLayout(txtField.getValue())
            self.win.hide();
          }
        },
        {
          text : "cancel",
          handler : function(){
            self.win.hide();
          }
        }]
      }],
    });
  },
  //Add a new track node
  manage: function(track){
    var self = this;
    if (!track instanceof Sv.tracks.BaseTrack) return;
    var parent = self.importPath(track.path);
    // Add Track to track browser
    self.trackBrowser.inactiveStore.add({
      id:   track.id,
      name: track.name,
      type: track.type,
      sampleType: track.sample_type,
      description: track.description,
      details: track.details,
      iconCls: track.iconCls,
      path: track.path
    })
    
    // handle external track close event
    track.on('close', self.inactivate);
    
    //Create the leaf node to represent the track
    var node = parent.appendChild(
      {
        itemId        : 'tree_leaf_node_' + track.config.id,
        text      : track.name,
        iconCls   : track.iconCls,
        allowDrag : true,
        allowDrop : false,
        editable  : false,
        expandable: false,
        leaf      : true
      });
      node.originalParent = parent;
      node.track = track;
      node.updatePath = function(newPath){
        BaseJS.request({
          url         : AnnoJ.config.updateNodePath,
          method      : 'POST',
          requestJSON : false,
          data        :
          {
            path    : newPath, 
            track_id : node.track.id
          },
        });
      };
      node.updateParent = function(newParent){
        if(node.originalParent!=newParent){
          node.originalParent = newParent;
          node.updatePath(newParent.data.text); 
        }
      }
      track.node = node;
      
      //Attach a listener for the node move event
      node.on('move', function(node, oldParent, newParent, index, options)
      {   
        if (oldParent == self.active)
        {          
          //Active to active (reorder)
          if (newParent == self.active)
          {
            var siblingTrack = node.nextSibling ? node.nextSibling.track : null
            self.fireEvent('moveTrack', node.track, siblingTrack);
            self.trackBrowser.moveTrack(node.track, siblingTrack);
          }
          //Active to wrong inactive (remove)
          else if (node.originalParent && newParent != node.originalParent)
          {
            node.updateParent(node.parentNode);
            self.fireEvent('closeTrack', node.track);
            self.trackBrowser.closeTrack(node.track);
          }
          //Active to right inactive (remove)
          else
          {
            self.fireEvent('closeTrack', node.track);
            //Update Browser
            self.trackBrowser.closeTrack(node.track);
          }
        }
        else
        {
          //Inactive to active (insert)
          if (newParent == self.active)
          {
            var siblingTrack = node.nextSibling ? node.nextSibling.track : null
            self.fireEvent('openTrack', node.track, siblingTrack);
            self.trackBrowser.openTrack(node.track, siblingTrack);
          }
          //Inactive to wrong inactive parent
          else if (node.originalParent && newParent != node.originalParent)
          {
            node.updateParent(node.parentNode);
          }
          //Inactive to inactive (reorder)
          else
          {
            return;
          }
        }
      });

  },
  //Remove a track node
  unmanage: function(track){
    if (!track instanceof AnnoJ.Track) return;
    if (!track.node) return;
    track.node.remove();
    node.track = null;
    delete track.node;
    track.un('close', inactivate);
  },
  //Inactivate a track
  inactivate: function(track){
    track.node.originalParent.appendChild(track.node);
  },
  //Inactivate all tracks
  inactivateAll: function(){
    Ext.each(this.active.childNodes, function(child)
    {
      inactivate(child.track);
    });
  },
  //Activate a track
  activate: function(track){
    this.active.appendChild(track.node);
  },
  //Display the save layout form
  showLayoutForm: function(){
    this.win.show();
  },
  //Tell App to save the layout with the given name
  postLayout: function(layout_name){
    AnnoJ.postLayout(layout_name);
  },
  //Toggle the active state of a track
  toggle_active: function(node){
    var self = this;
    if(node.parentNode==this.active){
      self.inactivate(node.track);
    }else{
      self.activate(node.track);
    }
  },
  //Create a Folder within the selector tree
  importPath: function(path){ 
    var dirs = path.split('/');
    var parent = this.inactive;
    var self = this;
    Ext.each(dirs, function(dir)
    {
      var child = parent.findChild('text', dir);
      if (!child)
      {
        child = self.createNewNode(dir)
        child = parent.appendChild(child);
      }
      parent = child;
    });
    return parent;
  },
  //return Hash of attributes for new Child
  createNewNode: function(text){
    child = {
      text      : text,
      allowDrag : false,
      allowDrop : true,
      leaf      : false,
      editable    : true,
      expanded  : true,
      expandable  : true,
      children : []
    }
    return child;
  },
  //Remove a folder and update its children
  removeNode: function(node){
    if( confirm("Remove the folder "+node.data.text+" ?") ){
      //update inactive children
      while(node.hasChildNodes())
      {
        child = node.firstChild;
        child.remove();
        node.parentNode.appendChild(child);
        child.updateParent(child.parentNode);
      }
      //update active children
      Ext.each(this.active.childNodes, function(child){
        if(child.originalParent == node)
        {
          child.updateParent(node.parentNode);
        }
      });
      //remove node
      node.remove();
      node.destroy();
    }
  },
  //Return a list of the active tracks
  getActive: function(){
    var list = [];      
    Ext.each(this.active.childNodes, function(child)
    {
      list.push(child.track);
    });
    return list;
  },        
  //Get a list of the active tracks' ids
  getActiveIDs: function(){
    var list = [];      
    Ext.each(this.active.childNodes, function(child)
    {
      list.push(child.track.id);
    });
    return list;
  },
  getActiveTrackString: function(){
    var me = this;
    s = "["
    Ext.each(this.active.childNodes, function(child){
      s+="'"+child.track.id+"'"
      if(child != me.active.lastChild){s+=",";}
    });
    s+= "]"
    return s
  }
});