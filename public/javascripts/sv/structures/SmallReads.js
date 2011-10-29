var SmallReadsList = function()
{
	SmallReadsList.superclass.constructor.call(this);

	var self = this;
	
	//Parse information coming from the server into the list
	this.parse = function(data, above)
	{
		if (!data) return;

		var reads = [];
		
		for (var name in data)
		{
			if (!data[name]['watson'] || !data[name]['crick']) continue;
			
			Ext.each(data[name][above ? 'watson' : 'crick'], function(datum)
			{
				if (datum.length != 6) return;
				
				var read = {
					cls      : name,
					strand   : above ? '+' : '-',
					id       : datum[0] || '',
					x        : parseInt(datum[1]) || 0,
					w        : parseInt(datum[2]) || 0,
					places   : parseInt(datum[3]) || 0,
					copies   : parseInt(datum[4]) || 0,
					sequence : datum[5] || ''
				};
				if (read.id && read.x && read.w && read.places && read.copies)
				{
					if (read.places > 1) read.cls += ' multi_mapper';
					if (read.copies > 1) read.cls += ' multi_copies';
					
					switch (read.w)
					{
						case 20: read.cls += ' sm21mers'; break;
						case 21: read.cls += ' sm22mers'; break;
						case 22: read.cls += ' sm23mers'; break;
						case 23: read.cls += ' sm24mers'; break;
						default: read.cls += ' Others'; break;
					}
					var node = self.createNode(read.id, read.x, read.x + read.w - 1, read);
					self.insert(node);
					//reads.push(node);
				}
			});
		}
		//self.insertArray(reads);
	};	
};
Ext.extend(SmallReadsList,ReadsList,{})
