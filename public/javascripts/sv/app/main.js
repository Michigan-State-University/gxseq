//AnnoJ singleton object
var AnnoJ = (function()
{	
    
	var defaultConfig = {
	    renderTo    : 'main',
		tracks    : [],
		active    : [],
		genome    : '',
		bookmarks : '',
		styles    : [],
		location  : {
			assembly : '3',
			position : 15678,
			bases : 25,
			pixels : 2
		},
		admin : {
			name  : '',
			email : '',
			notes : ''
		},
		cls : 'tracks',
		debug: true,
		citation : ''
	};
	var config = defaultConfig;
	var GUI = {};
	var height = 700;
		
	function init()
	{	
		//Clear any localStorage
		//localStorage.clear();
    
    //Check that the browser is compatible
		if (!WebApp.checkBrowser())
		{	
			WebApp.bombBrowser();
			return false;
		}
		
		//Create the message box
		var progressBar = Ext.Msg.show({progress: true});
		
		//Allowing GC to run will cause problems with the current appendTo, removeChild setup for track display.
		Ext.enableGarbageCollector = false;
		
		//Set configuration options
		progressBar.updateProgress(0.10, 'Applying configuration...');	
			
		if (!AnnoJ.config)
		{
			progressBar.hide();		
			WebApp.error('Unable to find configuation object (AnnoJ.config). The application cannot be built.');
			return false;
		}
		Ext.apply(config, AnnoJ.config || {}, defaultConfig);
		
		//Build the GUI
		progressBar.updateProgress(0.15, 'Building GUI...');	
		
		// try
		// {
			GUI = buildGUI();
		// }
	
		// catch (e)
		// {
		// 	Ext.MessageBox.hide();		
		// 	WebApp.exception(e, 'An exception was encountered when AnnoJ attempted to initialize the graphical user interface. Please notify the website administrator so that this may be addressed.');
		// 	return false;
		// };
		//GUI.notice('Browser check passed', true);
		//GUI.notice('Configuration loaded');
		//GUI.notice('GUI constructed');
		
		//Load the stylesheets
		//progressBar.updateProgress(0.3, '', 'Loading stylesheets...');
		//Ext.each(config.stylesheets, GUI.StyleSelector.manage);
		//GUI.notice('Stylesheets loaded');
		
		//Syndicate the genome
		progressBar.updateProgress(0.25, 'Loading genome...');
		GUI.NavBar.syndicate(
		{
			url : config.genome,
			bioentry : config.bioentry,
			success : function(response)
			{
				//GUI.notice('Genome syndicated');
				GUI.NavBar.setLocation(config.location);
				progressBar.updateProgress(0.5, 'Building tracks...');
				buildTracks();
				//GUI.notice('Tracks instantiated');				
				progressBar.updateProgress(1.0, 'Finished');
				progressBar.hide();
			},
			failure : function(string)
			{
				progressBar.hide();
				//error('Unable to load genomic metadata from address: ' + config.genome);
				Ext.MessageBox.alert('Error', 'Unable to load genomic metadata from address: ' + config.genome);
			}
		});
	 };
	//Build all the tracks
	function buildTracks()
	{
		GUI.TrackSelector.expand();
		Ext.each(config.tracks, function(trackConfig, index)
		{
			////Try to create the track defaulting to a base track if no plugin type is provided
      // try
      // {
				//var track = new Sv.tracks[trackConfig.type](trackConfig);
				var track = Ext.create("Sv.tracks."+trackConfig.type,trackConfig)
      // }
      // catch (e)
      // {
      //   config.tracks[index] = null;
      //   console.log("Track Creation Error: '"+e+"'");
      //   return;
      // };
			
			//Add the track to the track selector tree and the track main window
			GUI.Tracks.tracks.manage(track);
			GUI.TrackSelector.manage(track);
		});
		//Hook the info buttons of all of the tracks
		// Ext.each(GUI.Tracks.tracks.tracks, function(track)
		// {
		// 	track.on('describe', function(syndication)
		// 	{
		// 		GUI.InfoBox.echo(BaseJS.toHTML(syndication));
		// 	});
		// });
		//Activate the default tracks
		Ext.each(config.active, function(id)
		{
			var track = GUI.Tracks.tracks.find('id', id);
			if (track)
			{
				GUI.TrackSelector.activate(track);
				GUI.Tracks.tracks.open(track);
				//gene_id API  -  auto load InfoBox if the gene_model_id config property is set.
				if(config.gene_id && track instanceof Sv.tracks.ModelsTrack )
				{
				    track.lookupModel(config.gene_id)
				}
				//feature_id API  -  auto load InfoBox if the feature_id config property is set.
				if(config.feature_id && track instanceof Sv.tracks.GenericFeatureTrack )
				{
				    track.lookupModel(config.feature_id)
				}
			}
		});
		GUI.TrackSelector.active.expand();
		GUI.TrackSelector.inactive.expand();
		GUI.Viewport.doLayout();
	};
	
	//Build the GUI
	function buildGUI()
	{
		//Ext.Compat.showErrors = true;
		//Build the GUI components
		//var Messenger = new AnnoJ.Messenger();
        
    // Track Selector Tree
    var TrackSelector = new Sv.gui.TrackSelector({
     activeTracks : config.active
    });


		// var Bookmarker = new AnnoJ.Bookmarker({
		// 	datasource : config.bookmarks || config.genome
		// });
		// 
		// var StyleSelector = new AnnoJ.StyleSelector({
		// 	styles : config.styles
		// });

		var LayoutBox = new AnnoJ.LayoutBox();

		var InfoBox = new AnnoJ.InfoBox();
        InfoBox.hide();

    //var EditBox = new AnnoJ.EditBox();
    // EditBox.hide();

        // var AboutBox = new AnnoJ.AboutBox({
        //  admin : config.admin
        // });
		
		
		//var Bugs = new AnnoJ.Bugs();
		
		var NavBar = new AnnoJ.Navigator();
	
		var Tracks = new AnnoJ.Tracks({
			tbar : NavBar.ext,
			tracks : config.tracks,
			activeTracks : config.active
		});
		
		if (config.citation)
		{
			AboutBox.addCitation(config.citation);
		}
		
		var Accordion = Ext.create('Ext.panel.Panel',
		{
			title        : 'Configuration',
			region       : 'west',
			layout       : 'accordion',
			iconCls      : 'silk_wrench',
			collapsible  : true,
			split        : true,
			minSize      : 160,
			width        : 260,
			maxSize      : 400,
			margins      : '0 0 0 0',
			items : [
				//AboutBox,
				LayoutBox,
			  TrackSelector,
			  InfoBox,
        //EditBox,
			    //Bugs,
			    //Messenger
			    //StyleSelector,
			    //Bookmarker
			]
		});
		var Viewport = Ext.create('Ext.panel.Panel',
		{
			renderTo: config.renderTo,
			//width: 	 '100%',
			height: height,
			layout 	: 'border',
			items  	: [
				Accordion,
				Tracks
			]
		});
		//disable the context menu
		window.oncontextmenu = new Function("return false");
		//disable selection to avoid highlighting the tracks/buttons
		//document.getElementById('page-container').onselectstart = new Function("return false");
		Ext.EventManager.addListener(window, 'resize', function(){
    	    GUI.Viewport.doLayout();
    	});
		//Hook GUI components together via events
		NavBar.on('describe', function(syndication) {
			//InfoBox.echo(BaseJS.toHTML(syndication));
			//InfoBox.expand();
		});
		NavBar.on('browse', Tracks.tracks.setLocation);
		NavBar.on('dragModeSet', Tracks.setDragMode);
		Tracks.on('dragModeSet', NavBar.setDragMode);
		
        TrackSelector.on('openTrack', Tracks.tracks.open);
        TrackSelector.on('moveTrack', Tracks.tracks.reorder);
        TrackSelector.on('closeTrack', Tracks.tracks.close);
		
		return {
			//Messenger : Messenger,
			TrackSelector : TrackSelector,
			InfoBox : InfoBox,
			//EditBox : EditBox,
			LayoutBox: LayoutBox,
			//AboutBox : AboutBox,
			NavBar : NavBar,
			Tracks : Tracks,
			Accordion : Accordion,
			Viewport : Viewport,
			//alert : alert,
			//error : error,
			//warning : warning,
			//notice : notice
		};
	};
	
	//post current layout to the config URL
	function postLayout(layout_name){
		post_config = 
		{
			url         : config.layout_path,
			method      : 'POST',
			requestJSON : false,
			data				: 
			{
				name			: layout_name,
				bioentry_id : AnnoJ.config.bioentry,
				active_tracks	: GUI.TrackSelector.getActiveTrackString(),
				track_configurations : Ext.JSON.encode(getActiveTracks().getConfigs()),
				location	:  Ext.JSON.encode(getLocation())
			},
			success : function(){
				GUI.LayoutBox.refresh();
				GUI.LayoutBox.expand();	
			},
			failure : function(response){
				window.alert("Error: "+ response);
			}
		}
		BaseJS.request(post_config);
	};
	
	function getLocation() {
		return GUI.NavBar.getLocation();
	};
	function getTrack(id) {
	  return GUI.Tracks.tracks.find('id', id);
	    // return GUI.Track.tracks
	};
	function getActiveTracks() {
	  return GUI.Tracks.tracks;
	    // return GUI.Track.tracks
	};
	function setLocation(location) {
		return GUI.NavBar.setLocation(location);
	};
	function pixels2bases(pixels) {
		return GUI.NavBar.pixels2bases(pixels);
	};
	function bases2pixels(bases) {
		return GUI.NavBar.bases2pixels(bases);
	};
	function xpos2gpos(xpos) {
		return GUI.NavBar.xpos2gpos(xpos);
	};
	function gpos2xpos(gpos) {
		return GUI.NavBar.gpos2xpos(gpos);
	};
	function getGUI() {
		return GUI;
	};	
	function resetHeight(){
		//var total_height = GUI.Tracks.getFrameHeight();
		//total_height += GUI.NavBar.ext.getHeight();
		var total_height = 0;
		Ext.each(GUI.Tracks.tracks.active, function(t)
		{
			total_height+=(t.height+1)
		});
		if(total_height < height){
			total_height = height
		}
		GUI.Viewport.setHeight(total_height);
		GUI.Viewport.doLayout();
	};
	
	 return {
	 	ready           : true,
	 	init            : init,
		// alert           : alert,
		// error           : error,
		// warning         : warning,
		// notice          : notice,
		getTrack        : getTrack,
		getActiveTracks : getActiveTracks,
		getLocation     : getLocation,
		setLocation     : setLocation,
		pixels2bases    : pixels2bases,
		bases2pixels    : bases2pixels,
		xpos2gpos       : xpos2gpos,
		gpos2xpos       : gpos2xpos,
		getGUI          : getGUI,
		resetHeight			: resetHeight,
		Plugins         : {},
		Helpers         : {},
		postLayout			: postLayout
	 };
})();
