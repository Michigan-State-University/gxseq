function toggleRows(elm) {
 var rows = document.getElementsByTagName("TR");
 var newDisplay = "none";
 var thisID = elm.parentNode.parentNode.parentNode.id + "-";
 if(elm.className.match(/folder/))
  elm.style.backgroundImage = "url(images/folder.png)";
 else
  elm.style.backgroundImage = "url(images/arrow_closed.png)";
  
 // Are we expanding or contracting? If the first child is hidden, we expand
  for (var i = 0; i < rows.length; i++) {
   var r = rows[i];
   if (matchStart(r.id, thisID, true)) {
    if (r.style.display == "none") {
      newDisplay = "table-row"; //Netscape and Mozilla
      if(elm.className.match(/folder/))
       elm.style.backgroundImage = "url(images/folder-open.png)";
      else
       elm.style.backgroundImage = "url(images/arrow_open.png)";
    }
    break;
   }
 }
 // When expanding, only expand one level.  Collapse all desendants.
 var matchDirectChildrenOnly = (newDisplay != "none");
 for (var j = 0; j < rows.length; j++) {
   var s = rows[j];
   if (matchStart(s.id, thisID, matchDirectChildrenOnly)) {
     s.style.display = newDisplay;
     var cell = s.getElementsByTagName("TD")[0];
     var tier = cell.getElementsByTagName("DIV")[0];
     var folder = tier.getElementsByTagName("A")[0];
     if (folder.getAttribute("onclick") != null) {
     if(folder.className.match(/folder/))
      folder.style.backgroundImage = "url(images/folder.png)";
     else
      folder.style.backgroundImage = "url(images/arrow_closed.png)";
     }
   }
 }
}

function matchStart(target, pattern, matchDirectChildrenOnly) {
 var pos = target.indexOf(pattern);
 if (pos != 0) return false;
 if (!matchDirectChildrenOnly) return true;
 if (target.slice(pattern.length, target.length).indexOf("-") >= 0) return false;
 return true;
}

function collapseAllRows() {
  var rows = document.getElementsByTagName("TR");
  for (var j = 0; j < rows.length; j++) {
    var r = rows[j];
    //Set image
    var cell = r.getElementsByTagName("TD")[0]
    if(cell){
      var img = cell.getElementsByTagName("DIV")[0].getElementsByTagName("A")[0];
      if(img){
        if (img.getAttribute("onclick") != null) {
        if(img.className.match(/folder/))
          img.style.backgroundImage = "url(images/folder.png)";
        else
          img.style.backgroundImage = "url(images/arrow_closed.png)";
        }
      }
    }
    //hide
    if (r.id.indexOf("-") >= 0) {
      r.style.display = "none";
    }
  }
}

function showAllRows() {
 var rows = document.getElementsByTagName("TR");
 for (var j = 0; j < rows.length; j++) {
   var r = rows[j];
   //Show
   if (r.id.indexOf("-") >= 0) {
     r.style.display = "table-row";    
   }
   //Set image
   var cell = r.getElementsByTagName("TD")[0]
   if(cell){
     var img = cell.getElementsByTagName("DIV")[0].getElementsByTagName("A")[0];
     if(img){
       if (img.getAttribute("onclick") != null) {
       if(img.className.match(/folder/))
         img.style.backgroundImage = "url(images/folder-open.png)";
       else
         img.style.backgroundImage = "url(images/arrow_open.png)";
       }
     }
   }
 }
}
