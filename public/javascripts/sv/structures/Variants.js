var VariantsList = function()
{
    VariantsList.superclass.constructor.call(this);

    var self = this;

    //Parse information coming from the server into the list
    this.parse = function(data)
    {
        if (!data) return;

        // for (var name in data)
        // {  		
            Ext.each(data, function(datum)
            { 
                if (datum.length != 7) return;				
                var variant = {
                    cls     : datum[0],
                    id      : datum[1] || '',
                    x       : parseInt(datum[2]) || 0,
                    w       : parseInt(datum[3]) || 1,
                    ref     : datum[4],
                    alt     : datum[5],
                    qual    : parseInt(datum[6]) || 0
                };
                //setup the seq for display
                variant.pos = variant.x
                switch(variant.cls)
                {
                    case 'deletion':
                        variant.seq = variant.ref.substring(variant.alt.length);
                        variant.x += variant.alt.length;
                        variant.w = variant.seq.length;
                        break;
                    case 'insertion':
                        variant.seq = variant.alt.substring(variant.ref.length);
                        variant.w = variant.seq.length
                        variant.x += variant.ref.length
                        variant.x -= variant.w/2
                        break;
                    case 'match':
                        variant.seq = variant.ref;
                        break;
                    default:
                        variant.seq = variant.alt;
                }
                if (variant.id && variant.x && variant.ref)
                {
                    var node = self.createNode(variant.id, variant.x, variant.x + variant.w, variant);
                    self.insert(node);
                }
            });
        // }
    };

    //Returns a collection of points for use with a histogram canvas
    this.subset2canvas = function(x1, x2, bases, pixels)
    {
        var subset = [];
        var bases = parseInt(bases) || 0;
        var pixels = parseInt(pixels) || 0;

        if (!bases || !pixels) return subset;

        self.viewport.update(x1,x2);
        
        self.viewport.apply(function(node)
        {
            if (node.x2 < x1) return true;
            subset.push(
                {
                    id : node.id,
                    x : Math.round((node.x1 - x1) * pixels / bases),
                    w : Math.round((node.value.w) * pixels / bases) || 1,
                    pos : node.value.pos,
                    cls : node.value.cls,
                    ref : node.value.ref,
                    alt : node.value.alt,
                    qual : node.value.qual,
                    seq : node.value.seq
                });
                return true;
            });
            return subset;
        };
    };
Ext.extend(VariantsList,RangeList,{})
