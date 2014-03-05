var RatioData = function()
{
	var dataSet = [];
	this.clear = function()
	{
	  dataSet = [];
	};
	
	this.prune = function(x1,x2)
	{
		//series.prune(x1,x2)
	};

	this.parse = function(data)
	{
		if (!data) return;
		var length = data.length;
    for (var i = 0; i < length; i++) {
      var x = (data[i][0]|0);
      var y = parseFloat(data[i][1]);
      dataSet[x] = {x:x,y:y}
    };
	};
		
	this.subset2canvas = function(left, right, bases, pixels)
	{
    if(left<0){left=0}
    var item;
    var a = []
    var mult = pixels / bases;
    for (prop in dataSet) {
      //test range, also removes any properties from list
      if (prop >= (left-mult) && prop <= (right+mult)) {
        item=dataSet[prop]
        if (item.x) {
          a.push(
            {
              x: ((item.x-left) * mult)|0,
              y: item.y
            }
          )
        }
      }
    }
    return a.sort(function(a,b){return a.x-b.x});
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
        var y = Math.abs(item.y)
        if(y > max) max = y;
      }
    }
    return max;
	};
};