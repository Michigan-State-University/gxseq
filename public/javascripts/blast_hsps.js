var colors = [
  [40,'#511','< 40'],
  [50,'#844', '40-50'],
  [80,'A60', '50-80'],
  [200,'#572', '80-200'],
  [-1,'#0B0', '>= 200']
]

BlastHsp = function(config){
  config = config||{}
  config.width = config.width||500;
  config.height = config.height||300;
  config.renderTo = config.renderTo||'blasthsp';
  config.boxHeight = config.boxHeight||10;
  var per_pixel = config.length/config.width;
  
  var container = document.getElementById(config.renderTo);
  var canvas = document.createElement('CANVAS');
  var brush = canvas.getContext('2d');
  
  canvas.width = config.width;
  canvas.height = config.height;
  container.appendChild(canvas)
  
  function getColor(score){
    var index = 0;
    while(index < colors.length-1){
      if(score < colors[index][0]){
        return colors[index][1]
      }else{
        index+=1
      }
    }
    return colors[colors.length-1][1]
  }
  
  var me = this;
  
  me.draw = function(hits){
    var row = 0;
    hits.forEach(function(hsps){
      hsps.forEach(function(hsp){
        brush.fillStyle = getColor(hsp[2])
        
        var screenX = Math.round(hsp[0]/per_pixel);
        var screenW = Math.round(hsp[1]/per_pixel);
        if(screenW <= 0){
          screenW = Math.abs(screenW);
          screenX -= screenW;
        }
        console.log(getColor(hsp[2]))
        console.log(screenX)
        brush.fillRect(screenX,row*config.boxHeight,screenW,config.boxHeight-1);
      })
      row +=1;
    })
  };
};

BlastKey = function(config){
  config = config||{}
  config.width = config.width||500;
  config.renderTo = config.renderTo||'blast_key';
  config.boxHeight = config.boxHeight||10;
  var me = this;
  
  var container = document.getElementById(config.renderTo);
  var canvas = document.createElement('CANVAS');
  var brush = canvas.getContext('2d');
  canvas.width = config.width;
  canvas.height = config.boxHeight*2
  container.appendChild(canvas);
  brush.font = '12px bold'
  me.draw = function(){
    brush.fillStyle = 'black';
    brush.fillText("Color Key for alignment scores",300,config.boxHeight-2)
    var boxLength = Math.floor(config.width/colors.length);
    var step = 0;
    colors.forEach(function(color){
      brush.fillStyle = color[1];
      brush.fillRect(step,config.boxHeight,boxLength,config.boxHeight);
      brush.fillStyle='white';
      brush.fillText(color[2],step+((boxLength)/2.25),config.boxHeight*1.8)
      step+=boxLength;
    });
  };
}