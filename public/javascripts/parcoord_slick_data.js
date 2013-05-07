SlickParCoord = function(){
  var me = this;
  me.init = function(config){
    var path=config.path
    var par_selector=config.par
    var grid_selector=config.grid
    var page_selector=config.page
    var columns = config.grid_columns
    var chart_skip_keys = config.chart_skip_keys || []
    var chart_height = config.chart_height || 300
    var parcoords = d3.parcoords()(par_selector)
      .alpha(0.4)
      .mode("queue") // progressive rendering
      .height(chart_height)
      .margin({
        top: 36,
        left: 0,
        right: 0,
        bottom: 16
      });
    // create the chart
    display = function(data) {
      var keys = d3.keys(data[0]);
      // remove skipped keys
      chart_keys = keys.filter(function(key){
        return chart_skip_keys.every(function(skip_key){
          return skip_key!=key;
        })
      })
      parcoords
        .data(data)
        .detectDimensions()
        .dimensions(chart_keys)
        .render()
        //.reorderable()
        .brushable()
      // setting up grid
      var options = {
        enableCellNavigation: true,
        enableColumnReorder: false,
        multiColumnSort: false,
        forceFitColumns: true
      };

      var dataView = new Slick.Data.DataView();
      var grid = new Slick.Grid(grid_selector, dataView, columns, options);
      var pager = new Slick.Controls.Pager(dataView, grid, $(page_selector));

      // wire up model events to drive the grid
      dataView.onRowCountChanged.subscribe(function (e, args) {
        grid.updateRowCount();
        grid.render();
      });

      dataView.onRowsChanged.subscribe(function (e, args) {
        grid.invalidateRows(args.rows);
        grid.render();
      });

      // column sorting
      var sortcol = columns[0];
      var sortdir = 1;

      function comparer(a, b) {
        var x = a[sortcol], y = b[sortcol];
        return (x == y ? 0 : (x > y ? 1 : -1));
      }

      // click header to sort grid column
      grid.onSort.subscribe(function (e, args) {
        sortdir = args.sortAsc ? 1 : -1;
        sortcol = args.sortCol.field;

        if ($.browser.msie && $.browser.version <= 8) {
          dataView.fastSort(sortcol, args.sortAsc);
        } else {
          dataView.sort(comparer, args.sortAsc);
        }
      });

      // highlight row in chart
      grid.onMouseEnter.subscribe(function(e,args) {
        var i = grid.getCellFromEvent(e).row;
        var d = parcoords.brushed() || data;
        parcoords.highlight([d[i]]);
      });
      grid.onMouseLeave.subscribe(function(e,args) {
        parcoords.unhighlight();
      });

      // fill grid with data
      gridUpdate(data);

      // update grid on brush
      parcoords.on("brush", function(d) {
        gridUpdate(d);
      });

      function gridUpdate(data) {
        dataView.beginUpdate();
        dataView.setItems(data);
        dataView.endUpdate();
      };
    };
    // load data
    d3.json(path,display);
  }
  return me
}();