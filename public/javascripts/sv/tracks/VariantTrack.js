//Track to display variant information
Ext.define('Sv.tracks.VariantTrack',{
  extend : 'Sv.tracks.BrowserTrack',
  clsAbove : 'AJ_above',
  initComponent : function(){
    this.callParent(arguments);
    var self = this;
    //Initialize the DOM elements
    var containerA = new Ext.Element(document.createElement('DIV'));
    containerA.addCls(self.config.clsAbove);

    //Force some styles
    containerA.setStyle('position', 'relative');
    containerA.setStyle('width', '100%');
    containerA.setStyle('height', '100%');
    containerA.appendTo(self.Canvas.ext);

      // Function to retrieve selected data
      this.getSelectedData = function(){
          selectedDataBody.update("Loading..");
          BaseJS.request({
              url     : self.data,
              method  : 'GET',
              requestJSON : false,
              data : {
                  jrws : Ext.encode({
                      method  : 'select_region',
                      param   : {
                          id  : self.id,
                          left: self.selectStart,
                          right: self.selectEnd,
                          bioentry: self.bioentry
                      }
                  })
              },
              success: function(response){
               selectedDataBody.update(response.data.text);
               selectWindowForm.doComponentLayout();
              },
              failure: function(response){
               selectedDataBody.update("Oops! Something went wrong.");
              }
          });
      }
      // Div for rendering returned data
      var selectedDataBody = new Ext.Element(document.createElement('DIV'));
        // // Form for use with select window
        // // Allows adjusting of window start / stop position
        // // Displays html return from request
                        var selectWindowForm = new Ext.form.Panel({
                             labelAlign: 'right',
                             frame: true,
                             monitorValid:true,
                             autoScroll:true,
                             width:'90%',
                             fieldDefaults: {
                                 labelAlign: 'top',
                                 msgTarget: 'side'
                             },
                             buttons:[{
                                 text: 'Close',
                                 handler: function(){
                                     selectWindow.hide();
                                 }
                             }],
                             items: [
                                   new Ext.form.FieldSet({
                                       title: 'Selected Location',
                                       itemId: "fs",
                                       autoHeight: true,
                                       //labelWidth: 30,
                                       anchor: '100%',
                                       layout: 'column',
                                       items: [
                                        {
                                            itemId: "select_start",
                                            xtype: 'numberfield',
                                            fieldLabel: 'Start',
                                            name: 'start_pos',
                                            columnWidth:.5,
                                            allowBlank: false,
                                            minValue: 1,
                                            allowDecimals: false,
                                            enableKeyEvents: true,
                                            listeners: {
                                                change : {
                                                    fn : function(field, newValue, oldValue){
                                                        if(selectWindowForm.getForm().isValid()){
                                                            self.selectStart = newValue;
                                                            self.getSelectedData();
                                                        }
                                                    }
                                                },
                                                specialkey: {
                                                    fn : function (field,e){
                                                        if (e.getKey() == e.ENTER) {
                                                            this.fireEvent("change");
                                                        }
                                                    }
                                                }
                                            }
                                        },
                                        {
                                            itemId: "select_end",
                                            xtype: 'numberfield',
                                            fieldLabel: 'End',
                                            name: 'end_pos',
                                            columnWidth:.5,
                                            allowBlank: false,
                                            minValue: 2,
                                            allowDecimals: false,
                                            enableKeyEvents: true,
                                            listeners: {
                                                change : {
                                                    fn : function(field, newValue, oldValue){
                                                        if(selectWindowForm.getForm().isValid()){
                                                            self.selectEnd = newValue;
                                                            self.getSelectedData();
                                                        }
                                                    }
                                                },
                                                specialkey: {
                                                    fn : function (field,e){
                                                        if (e.getKey() == e.ENTER) {
                                                            this.fireEvent("change");
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    ]
                                   }),
                                   new Ext.form.FieldSet({
                                       title: '',
                                       width:'90%',
                                       autoHeight:true,
                                       items:[{
                                           contentEl: selectedDataBody
                                       }]
                                   })
                               ],
                         });
        
        // selectWindow for use with select event
        var selectWindow = new  Ext.Window({
                    x: 300,
                    y: 300,
                    width:425,
                    minWidth:325,
                    height:400,
                    plain:true,
                    title:'Variant Sequence From '+self.name,
                    layout:'fit',
                    border:false,
                    closable:true,
                    closeAction:'hide',
                    items : [
                        selectWindowForm 
                    ]
                 });
        
    // allow select event
    this.removeListener("selectStart",this.cancelSelectStart);
    
       this.on("selectEnd", function(startPos,endPos){
           //Really?  can this be done better...
           selectWindowForm.getComponent("fs").getComponent("select_start").setValue(startPos);
           selectWindowForm.getComponent("fs").getComponent("select_end").setValue(endPos);
           self.selectStart = startPos;
           self.selectEnd = endPos;      
          selectWindow.show();
           if(selectWindowForm.getForm().isValid())
           {
               self.getSelectedData();
           }
           else
           {
               selectedDataBody.update("Invalid selection. Please refine your search");
           }
    });

    //function to handle clicks
    this.lookupItem = function(pos){
      box = AnnoJ.getGUI().InfoBox;
      box.show();
      box.expand();
      box.echo("<div class='waiting'>Loading...</div>");
      Ext.Ajax.request(
      {
        url         : self.data,
        method      : 'GET',
        params      :{
          jrws : Ext.encode({
              method  : 'describe', 
              param   : {
                pos : pos,
                bioentry : self.bioentry,
                experiment : self.experiment}
              })
        },
        success  : function(response){
            box.echo(response.responseText);
            box.setTitle(self.name)
        },
        failure  : function(message){
          box.echo("Error: failed to retrieve gene information:<br/>"+message);
        }
      });
    };

    //handler
    var VariantList = (function()
    {
      var dataA = new VariantsList();

      function parse(data)
      {
        for (var series in data)
        {
          addLabel(series);
        }
        dataA.parse(data,true);
      };

      var canvasA = new Sv.painters.VariantsCanvas();
      canvasA.setContainer(containerA.dom);
      canvasA.on('itemSelected', self.lookupItem);

      function paint(left, right, bases, pixels)
      {
        var subsetA = dataA.subset2canvas(left, right, bases, pixels);

        canvasA.setData(subsetA);
        requested_pixels = canvasA.paint(); //paint and retrieve required canvas height
        new_height = requested_pixels + 30+35; //add room for the toolbar plus
        //Match canvas height to requested height from painter
        if(self.getMaxHeight() >= new_height && new_height >= self.getMinHeight())
        {
            self.setHeight(new_height);
        }
        else if(self.getMaxHeight() < new_height)
        {   self.setHeight(self.getMaxHeight());}
        else if(self.getMinHeight() > new_height)
        {   self.setHeight(self.getMinHeight());}

      };

      return {
        dataA : dataA,
        canvasA : canvasA,
        parse : parse,
        paint : paint
      };
    })();

    //Data handling and rendering object
    var handler = VariantList;

    //Zoom policies (dictate which handler to use)
    var policies = [
      { index:0, min:1/100 , max:1/1    , bases:1   , pixels:10 , cache:1000     },
      { index:1, min:1/1   , max:10/1   , bases:1   , pixels:1  , cache:10000    },
      { index:2, min:10/1  , max:100/1  , bases:10  , pixels:1  , cache:100000   },
      { index:3, min:100/1 , max:1000/1 , bases:100 , pixels:1  , cache:1000000  },
      { index:4, min:1000/1, max:10000/1, bases:1000, pixels:1  , cache:10000000 }
    ];

    //Data series labels
    var labels = null;

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
                       handler.canvasA.groups.toggle(name, !this.checked);
                       handler.canvasA.refresh();
                   }
               })
           ]);
          }
    };

    this.getPolicy = function(view)
    {
      var ratio = view.bases / view.pixels;

      handler = VariantList;

      for (var i=0; i<policies.length; i++)
      {
        if (ratio >= policies[i].min && ratio < policies[i].max)
        {     
          return policies[i];
        }
      }
      return null;
    };
    this.rescale = function(f)
    {
      var f = Math.pow(f*2, 4);
      handler.canvasA.setScaler(f);
      handler.canvasA.refresh();
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
    this.requestFrame = function(frame,pos,policy){
  	  Ext.Ajax.request({
          url: self.data,
          method: 'GET',
          params: {
              jrws: Ext.encode({
                  method: 'range',
                  param: {
                      id: self.id,
                      experiment: self.experiment,
                      left: pos.left,
                      right: pos.right,
                      bases: policy.bases,
                      pixels: policy.pixels,
                      bioentry: self.bioentry,
                      sample : self.sample
                  }
              })
          },
          success: function(response)
          {
              response = Ext.JSON.decode(response.responseText);
              self.DataManager.parse(response.data, frame);
              self.DataManager.views.loading = null;
              self.DataManager.state.busy = false;
              self.setTitle(self.name);
              self.DataManager.setLocation(self.DataManager.views.requested);
          },
          failure: function(message)
          {
              console.error('Failed to load data for track ' + self.name + ' (' + message + ')');
              self.DataManager.views.loading = null;
              self.DataManager.state.busy = false;
              self.setTitle(self.name);
          }
      });
  	};
  }
});