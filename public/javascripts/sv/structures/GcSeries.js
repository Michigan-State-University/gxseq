var SeriesList = function()
{

  SeriesList.superclass.constructor.call(this);

  var self = this;
  var pe = false;

  this.parse = function(data)
  {
    if (!data) return;

    var sequence = [];
    for (var name in data)
    {   
      if (!data[name]['gc_content']) continue;
      Ext.each(data[name]['gc_content'], function(datum)
      {
        if (datum.length != 4) return;
        var sequence = {
          cls      : 'GC',
          id       : datum[0] || '',
          x        : parseInt(datum[1]) || 0,
          w        : parseInt(datum[2]) || 0,
          seqlist : datum[3] || ''
        };
        if (sequence.id && sequence.x >=0 && sequence.w >=0 && sequence.seqlist)
        {  
          var node = self.createNode(sequence.id, sequence.x, sequence.x + sequence.w - 1, sequence);
          self.insert(node);
        }
      });   
    }
  };

  this.subset2canvas = function(x1, x2, bases, pixels)
  {
    var subset = [];
    var bases = parseInt(bases) || 0;
    var pixels = parseInt(pixels) || 0;
    var countSeqLists = 0;
    var cnt = 0;
    if (!bases || !pixels) return subset;

    self.viewport.update(x1,x2);
    self.viewport.apply(function(node)
    {
      if (node.x2 < x1) return true;

      var ratio = bases / pixels;
      subset.push(
        {
          x : Math.round((node.x1 - x1) * pixels / bases),
          w : Math.round((node.value.w) * pixels / bases) || 1,
          cls : node.value.cls,
          bases: bases,
          pixels: pixels,
          seqlist : node.value.seqlist
        });
        return true;
      });    
      return subset;
    };
  };
Ext.extend(SeriesList,RangeList,{})