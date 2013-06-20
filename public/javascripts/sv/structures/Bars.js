var HistogramData = function()
{
	var dataSet = [];
	this.clear = function()
	{
	  dataSet = [];
		//series.clear()
	};
	
	this.prune = function(x1,x2)
	{
		//series.prune(x1,x2)
	};

	this.parse = function(data, above)
	{
		if (!data) return;
		var cnt=1;
		//series.parse(data);
		var length = data.length;
    for (var i = 0; i < length; i++) {
      var x = (data[i][0]|0)
      dataSet[x] = {x:x,y:parseFloat(data[i][1])}
    };
    for (prop in dataSet) {
      if (prop > 0) cnt+=1;
    }
	};
		
	this.subset2canvas = function(left, right, bases, pixels)
	{
    if(left<0){left=0}
    var item;
    var a = []
    for (prop in dataSet) {
      //test range, also removes an properties from list
      if (prop > left && prop < right) {
        item=dataSet[prop]
        if (item.x) {
          a.push(
            {
              x: (((item.x-left) * pixels / bases) | 0),
              y: item.y,
              w: 1
            }
          )
        }
      }
    }
    return a;
	};
	
	this.getMaxY = function(left, right)
	{
    if(dataSet.length == 0) return 0;
    if(left<0) left=0;
    var item;
    var max=0
    for (prop in dataSet) {
      //test range, also removes any properties from list
      if (prop >= left && prop <= right) {
        item=dataSet[prop];
        if(item.y > max) max = item.y;
      }
    }
    return max;
	};
};