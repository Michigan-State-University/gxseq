/*
 * Add various extensions to the core Javascript objects
 *
 * Copyright 2008 Julian Tonti-Filippini (tontij01(at)student.uwa.edu.au)
 * License: you are free to do whatever you wish with the code in this file, even claim it as your own.
 * Disclaimer: you use this code at your own risk.
 */

//Find the greatest common denominator of two integers using Euler's method
Math.gcd = function(a,b)
{
	var a = a ? parseInt(a) : 1;
	var b = b ? parseInt(b) : 1;
	
	var n = a > b ? a : b; //numerator
	var d = a > b ? b : a; //denominator
	var r = 0; //remainder
	
	while (true)
	{
		r = n % d;
		if (r == 0) break;
		n = d;
		d = r;
	}
	return d;
};

//Simplify a fraction
Math.simplify = function(n,d)
{
	var n = n ? parseInt(n) : 1;
	var d = d ? parseInt(d) : 1;
	
	var gcd = Math.gcd(n,d);		
	return [n/gcd, d/gcd];
};

//Removes the specified item from an array, returning false if the item is not in the array
Array.prototype.remove = function(item)
{
	for (var i=0, len=this.length; i<len; i++)
	{
		if (this[i] == item)
		{
			this.splice(i,1);
			return true;
		}
	}
	return false;
};

//Add the specified item to the array in the specified position
Array.prototype.insert = function(index, item)
{
	var index = parseInt(index) || null;
	
	if (index == null || index >= this.length || index < 0)
	{
		this.push(item);
		return;
	}
	this.splice(index,0,item);
};

//Returns the array index of the specified item or -1 if the item is not in the array
Array.prototype.search = function(item)
{
	for (var i=0, len=this.length; i<len; i++)
	{
		if (this[i] == item)
		{
			return i;
		}
	}
	return -1;
};

// Returns the reverse of a passed in string
String.prototype.reverse = function()
{
  splitext = this.split("");
  revertext = splitext.reverse();
  reversed = revertext.join("");

  return reversed;
};

/*
 * Add extensions to ExtJS for custom functionality, warning the user if Ext is not available
 */
if (!Ext)
{
	var html = "<div style='margin:auto; width:600px; border:solid black 1px; padding:15px; margin-top:100px; font-family:arial; font-size:13px;'>";
	html += "<h1>Error: Ext not found</h1><br />";
	html += "<p>This application could not find the ExtJS Javascript libraries and consequently, cannot run.</p>";
	html += "<ul style='padding:10px; list-style:circle; font-size:12px;'>";
	html += "<li>Check that ExtJS libraries are included in the document &lt;head&gt; section</li>";
	html += "<li>Check that ExtJS libraries are included before this error checking routine</li>";
	html += "<li>Check that ExtJS libraries are being referenced from a correct URL</li>";
	html += "<li>Check that your internet connection is active</li>";
	html += "</ul>";
	html += "<p>Please notify your website administrator of this problem so that it may be fixed.</p>";
	html += "<p>ExtJS is available from <a href='http://www.extjs.com'>http://www.extjs.com</a></p>";
	html +=	"<p><a href='http://www.extjs.com/download'><img src='img/extjs.png' alt='Get ExtJS 2' /></a>";
	html += "</div>";
	
	window.onload = function() {
		document.body.innerHTML = html;
	};
}
else
{
	Ext.Ajax.timeout =30000;
	Ext.QuickTips.init();

  // Extend slider to move thumb according to thumb width. Allow for dynamic thumb widths in app
  // 
  Ext.ux.SliderShift = (function(){     
       return {
          
           init: function(f) {
               f.normalizeValue = this.normalizeValue;
           },
           
           // Add new constraints for variable-width-thumb. (Scrollbar)
           normalizeValue : function(v){
               var me = this;
               if(!me.innerEl) return;
               
               var thumb = me.thumbs[0].el;
               var offset = Math.floor(me.halfThumb)/me.getRatio();
               v = Ext.Number.snap(v, me.increment, (me.minValue+offset), (me.maxValue-offset));
               v = Ext.util.Format.round(v, me.decimalPrecision);                                      
               v = Ext.Number.constrain(v,(me.minValue+offset), (me.maxValue-offset));
               return v;
           },

       };
   })();

    /* @class Ext.ux.tree.TreeEditing
    * @extends Ext.grid.plugin.CellEditing
    * @license Licensed under the terms of the Open Source <a href="http://www.gnu.org/licenses/lgpl.html">LGPL 3.0 license</a>.  Commercial use is permitted to the extent that the code/component(s) do NOT become part of another Open Source or Commercially licensed development library or toolkit without explicit permission.
    * http://www.sencha.com/forum/showthread.php?138056-TreeEditor-plugin-until-Ext-releases-native
    * @version 0.1 (June 22, 2011)
    * @constructor
    * @param {Object} config 
    */
   Ext.define('Ext.ux.tree.TreeEditing', {
       alias: 'plugin.treeediting'
       ,extend: 'Ext.grid.plugin.CellEditing'


       /**
        * @override
        * @private Collects all information necessary for any subclasses to perform their editing functions.
        * @param record
        * @param columnHeader
        * @returns {Object} The editing context based upon the passed record and column
        */
       ,getEditingContext: function(record, columnHeader) {
              var me = this,
               grid = me.grid,
               store = grid.store,
               rowIdx,
               colIdx,
               view = grid.getView(),
               root = grid.getRootNode(),
               value;

           // If they'd passed numeric row, column indices, look them up.
           if (Ext.isNumber(record)) {
               rowIdx = record;
               record = root.getChildAt(rowIdx);
           } else {
               rowIdx = root.indexOf(record);
           }
           if (Ext.isNumber(columnHeader)) {
               colIdx = columnHeader;
               columnHeader = grid.headerCt.getHeaderAtIndex(colIdx);
           } else {
               colIdx = columnHeader.getIndex();
           }

           value = record.get(columnHeader.dataIndex);
           return {
               grid: grid,
               record: record,
               field: columnHeader.dataIndex,
               value: value,
               row: view.getNode(rowIdx),
               column: columnHeader,
               rowIdx: rowIdx,
               colIdx: colIdx
           };
       }

   });//eo class
}
