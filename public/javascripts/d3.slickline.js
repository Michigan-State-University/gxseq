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
      
  var display = function(error,rawData){
    var grid = new Slick.Grid(grid_selector, rawData, columns, options);
    grid.setSelectionModel(Slick.RowSelectionModel);
    // highlight row in linechart on change
    grid.onMouseEnter.subscribe(function(e,args) {
      var i = grid.getCellFromEvent(e).row;
      var d = rawData;
      linechart.highlight(d[i].id);
    });
    grid.onMouseLeave.subscribe(function(e,args) {
      var i = grid.getCellFromEvent(e).row;
      var d = rawData;
      linechart.unhighlight(d[i].id);
    }); 
    // Setup chart with handler
    var linechart = d3.linechart({
      graph:graph_selector,
      path:path,
      tooltip:tooltip,
      mouseclick:function(){
        idx = rawData.indexOf(this);
        grid.scrollRowIntoView(idx);
        grid.setActiveCell(idx,1);
      }})
    //Sort handler
    grid.onSort.subscribe(function(e, args){ // args: sort information. 
      var field = args.sortCol.field;
      rawData.sort(function(a, b){
          var result = 
              a[field] > b[field] ? 1 :
              a[field] < b[field] ? -1 :
              0;
          return args.sortAsc ? result : -result;
      });
      grid.invalidate();         
    });
    // Render chart
    linechart.render(rawData);
  }
  
  slick.load = function(path){
    d3.json(path,display);
  }
  
  return slick
}