d3.slickline = function(config){
  var slick = {};
  var path=config.path;
  var tooltip = config.tooltip;
  var graph_selector=config.graph;
  var grid_selector=config.grid;
  var page_selector=config.pager;
  var columns = config.grid_columns;
  var handLineChartMouseOver;
  
  // setting up grid
  var options = {
    enableCellNavigation: true,
    enableColumnReorder: false,
    multiColumnSort: false,
    forceFitColumns: true,
    autoEdit: false
  };

  var dataView = new Slick.Data.DataView();
  var grid = new Slick.Grid(grid_selector, dataView, columns, options);
  var pager = new Slick.Controls.Pager(dataView, grid, $(page_selector));
  
  grid.setSelectionModel(Slick.RowSelectionModel);
  // wire up model events to drive the grid
  dataView.onRowCountChanged.subscribe(function (e, args) {
    grid.updateRowCount();
    grid.render();
  });
  
  dataView.onRowsChanged.subscribe(function (e, args) {
    grid.invalidateRows(args.rows);
    grid.render();
  });
  
  function gridUpdate(data) {
    dataView.beginUpdate();
    dataView.setItems(data);
    dataView.endUpdate();
  };
  
  var display = function(error,rawData){
    
    gridUpdate(rawData);
    
    // highlight row in linechart on change
    grid.onMouseEnter.subscribe(function(e,args) {
      var i = grid.getCellFromEvent(e).row;
      var d = rawData;
      linechart.highlight(d[i].id);
    });
    grid.onMouseLeave.subscribe(function(e,args) {
      linechart.unhighlight();
    }); 
    // Setup chart with handler
    var linechart = d3.linechart({
      graph:graph_selector,
      path:path,
      tooltip:tooltip,
      mouseover:function(){
        grid.scrollRowIntoView(this);
        grid.setActiveCell(this,1);
      }})
    // Render chart
    linechart.render(rawData);
  }
  
  slick.load = function(path){
    d3.json(path,display);
  }
  
  return slick
}