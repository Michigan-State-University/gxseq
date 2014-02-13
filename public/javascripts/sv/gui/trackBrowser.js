// Set up a model to use in our Store
Ext.define('SampleTrack', {
    extend: 'Ext.data.Model',
    fields: [
      {name: 'id',            type: 'int'},
      {name: 'name',          type: 'string'},
      {name: 'type',          type: 'string'},
      {name: 'sampleType',    type: 'string'},
      {name: 'description',   type: 'string'},
      {name: 'details',       type: 'string'},
      {name: 'path',          type: 'string'}
    ]
});
//Track Browser component
// This component based on LiveSearchGrid @author Nicolas Ferrero
Ext.define('Sv.gui.TrackBrowser',{
  extend:'Ext.Window',
  requires: [
    'Ext.dd.*',
    'Ext.ux.statusbar.StatusBar'
  ],
  title: 'Track Browser',
  x: 200,
  y: 100,
  width:800,
  maxHeight:1500,
  maxWidth:1600,
  minWidth:400,
  height:700,
  layout:{
    type:'vbox',
    align: 'stretch'
  },
  closable:true,
  closeAction:'hide',
  //Constructor
  initComponent: function(){
    var me = this;
    me.callParent(arguments);
    //Add custom events
    me.addEvents({
      'openTrack' : true,
      'closeTrack' : true,
      'removeTrack'  : true,
      'insertTrack' : true
    });
    //Data store
    me.inactiveStore = Ext.create('Ext.data.Store', {
      model: 'SampleTrack',
      storeId:'employeeStore',
      //groupField: 'department',
    });

    me.activeStore = Ext.create('Ext.data.Store', {
      model: 'SampleTrack',
      storeId:'emptyEmployeeStore',
    });
    //Config setup
    var gridColumns = [
      {
        text: 'Folder',
        dataIndex: 'path',
        flex:1,
        sortable: true
      },
      {
        text: 'Icon',
        dataIndex: 'iconCls',
        renderer: function(value,metadata){
          metadata.tdCls = metadata.tdCls + ' ' + value;
        },
        width:16,
        sortable: true
      },
      {
        text: 'Sample Type',
        dataIndex: 'sampleType',
        flex:1,
        sortable: true
      },
      {
        text: 'Track Type',
        dataIndex: 'type',
        flex:1,
        sortable: true
      },
      {
        text: 'Name',
        dataIndex: 'name',
        flex:2,
        sortable: true
      },
      {
        text: 'Description',
        dataIndex: 'description',
        flex:3,
        sortable: true
      },
      {
        text: 'Details',
        dataIndex: 'details',
        flex:3,
        sortable: true
      }
    ]
    var activeColumns =[
        {
          text: 'Icon',
          dataIndex: 'iconCls',
          renderer: function(value,metadata){
            metadata.tdCls = metadata.tdCls + ' ' + value;
          },
          flex:1,
          sortable: false
        },
        {
          text: 'Name',
          dataIndex: 'name',
          flex:2,
          sortable: false
        },
        {
          text: 'Description',
          dataIndex: 'description',
          flex:3,
          sortable: false
        },
        {
          text: 'Details',
          dataIndex: 'details',
          flex:3,
          sortable: false
        },
        // Move Up / Move Down icons need work
        // {
        //   text: 'Options',
        //   xtype:'actioncolumn',
        //   flex:1,
        //   items: [{
        //       icon: '/images/arrow_up.png',
        //       iconCls: 'grey_icon_button',
        //       tooltip: 'Move Up',
        //       handler: function(grid, rowIndex, colIndex) {
        //           var record = grid.getStore().getAt(rowIndex);
        //           newIdx = record.store.indexOf(record)-1
        //           me.removeTrackRecord(record);
        //           me.insertTrackRecord(record,newIdx);
        //       }
        //   },
        //   {
        //   },
        //   {
        //       icon: '/images/arrow_down.png',
        //       iconCls: 'grey_icon_button',
        //       tooltip: 'Move Down',
        //       handler: function(grid, rowIndex, colIndex) {
        //           var record = grid.getStore().getAt(rowIndex);
        //           newIdx = record.store.indexOf(record)+1
        //           me.removeTrackRecord(record);
        //           me.insertTrackRecord(record,newIdx);
        //       }
        //   }]
        // }
    ]
    //Inactive Grid
    me.inactiveGrid = Ext.create('Ext.ux.LiveSearchGridPanel',{
      title : "All Tracks",
      itemId : 'inactiveGridPanel',
      store: 'employeeStore',
      flex: 5,
      autoScroll:true,
      multiSelect: true,
      stripeRows: true,
      forceFit: true,
      defaultStatusText: "No Search Results",
      columns: gridColumns,
      viewConfig: {
        plugins: {
            ptype: 'gridviewdragdrop',
            ddGroup: 'TrackBrowserDD'
        },
        listeners: {
            drop: function(node, data, dropRec, dropPosition) {
              Ext.each(data.records, function(record){
                  me.closeTrackRecord(record);
              });
            }
        }
      }
    });
    //Active Grid
    me.activeGrid = Ext.create('Ext.grid.Panel',{
      title : "Active Tracks",
      itemId : 'activeGridPanel',
      store: 'emptyEmployeeStore',
      flex: 4,
      autoScroll:true,
      multiSelect: true,
      stripeRows: true,
      sortableColumns: false,
      forceFit: true,
      columns: activeColumns,
      viewConfig: {
        plugins: {
            ptype: 'gridviewdragdrop',
            ddGroup: 'TrackBrowserDD'
        },
        listeners: {
            drop: function(node, data, overModel, dropPosition) {
              //For multiple items first remove all then add all
              var recordIds = []
              Ext.each(data.records, function(record){
                recordIds.push(this.store.indexOf(record))
                me.removeTrackRecord(record);
              });
              Ext.each(data.records, function(record,idx){
                me.insertTrackRecord(record,recordIds[idx]);
              });
              
            },
            itemcontextmenu: function(thisView, record, htmlItem, index, event, opts){
              event.stopEvent();
              var track = me.trackManager.tracks.find('id',record.data.id)
              track.contextMenu.ext.showAt([event.getPageX(), event.getPageY()]);
            }
        }
      },
    });
    // Middle Buttons
    me.activateButton = Ext.create("Ext.button.Button",{
      iconCls: 'silk_arrow_up',
      disabled: true,
      padding: '15 20',
      margin: '0 10 0 0',
      handler: function(){
        Ext.each(me.inactiveGrid.getSelectionModel().getSelection(), function(row){
          me.openTrackRecord(row);
        })
        me.activateButton.disable();
        me.deActivateButton.disable();
      }
    });
    me.deActivateButton = Ext.create("Ext.button.Button",{
      iconCls: 'silk_arrow_down',
      disabled: true,
      padding: '15 20',
      margin: '0 10 0 0',
      handler: function(){
        Ext.each(me.activeGrid.getSelectionModel().getSelection(), function(row){
          me.closeTrackRecord(row);
        })
        me.activateButton.disable();
        me.deActivateButton.disable();
      }
    });
    me.sep = Ext.create('Ext.container.Container',{
      layout:{
        type:'hbox',
        pack: 'center',
        align:'middle',
      },
      width:"100%",
      flex:1,
      items: [me.activateButton,me.deActivateButton]
    })
    
    //Add the Grids
    me.add([me.activeGrid,me.sep,me.inactiveGrid]);
    
    /// EVENTS
    
    //Double Click - toggle items
    me.activeGrid.on('itemdblclick',function(thisView, record, htmlItem, index, event, opts){      
      me.closeTrackRecord(record);
      me.activateButton.disable();
      me.deActivateButton.disable();
    });
    me.inactiveGrid.on('itemdblclick',function(thisView, record, htmlItem, index, event, opts){      
      me.openTrackRecord(record);
      me.activateButton.disable();
      me.deActivateButton.disable();
    });
    // Select - set transfer button state
    me.activeGrid.on('select',function(thisView, record, index, opts){
      me.activateButton.disable();
      me.deActivateButton.enable();
      me.inactiveGrid.getSelectionModel().deselectAll();
    });
    me.inactiveGrid.on('select',function(thisView, record, index, opts){
      me.activateButton.enable();
      me.deActivateButton.disable();
      me.activeGrid.getSelectionModel().deselectAll();
    });
    
  },
  //// Bubble Up Events
  //Fire a move event
  openTrackRecord: function(record, index){
    var track = this.trackManager.tracks.find('id',record.data.id);
    this.fireEvent('openTrack',track,index);
  },
  removeTrackRecord: function(record){
    var track = this.trackManager.tracks.find('id',record.data.id);
    this.fireEvent('removeTrack',track);
  },
  insertTrackRecord: function(record, index){
    var track = this.trackManager.tracks.find('id',record.data.id);
    this.fireEvent('insertTrack',track,index);
  },
  closeTrackRecord: function(record){
    var track = this.trackManager.tracks.find('id',record.data.id)
    this.fireEvent('closeTrack',track)
  },
  openTrack: function(track,nextTrack){
    var record = this.inactiveStore.findRecord('id',track.id);
    if(!record) return;
    record.store.remove(record);
    if(nextTrack){
      var nextIdx = this.activeStore.find('id',nextTrack.id);
      this.activeStore.insert(nextIdx,record);
    }else{
     this.activeStore.add(record);
    }
  },
  // Top Down Actions
  closeTrack: function(track){
    var record = this.activeStore.findRecord('id',track.id);
    if(!record) return;
    record.store.remove(record);
    this.inactiveStore.insert(0,record);
  },
  moveTrack: function(track, nextTrack){
    var record = this.activeStore.findRecord('id',track.id)
    if(!record) return;
    record.store.remove(record);
    if(nextTrack){
      var nextIdx = this.activeStore.find('id',nextTrack.id);
      this.activeStore.insert(nextIdx,record);
    }else{
     this.activeStore.add(record);
    }
  }
});