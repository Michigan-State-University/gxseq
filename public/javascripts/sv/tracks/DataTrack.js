Ext.define('Sv.tracks.DataTrack', {
    extend: 'Sv.tracks.BaseTrack',
    datasource: '',
    initComponent: function() {
        this.callParent(arguments);
        var self = this;
        //AJAX communications. (NOTE: Will add a query queue later if needed)
        this.Communicator = (function()
        {
            var busy = false;

            //Check if a request is currently executing
            function isBusy()
            {
                return busy;
            };

            //Conduct a GET request
            function get(data, options)
            {
                var options = Ext.apply(options || {},
                {
                    method: 'GET'
                });
                return request(data, options);
            };

            //Conduct a POST request
            function post(data, options)
            {
                var options = Ext.apply(options || {},
                {
                    method: 'POST'
                });
                return request(data, options);
            };

            //Conduct an AJAX request
            function request(data, options)
            {
                if (busy) return false;

                self.setTitle('<span class="waiting">Communicating with server...</span>');

                var options = Ext.apply(options || {},
                {},
                {
                    url: self.datasource,
                    method: 'POST',
                    data: data || null,
                    success: function() {},
                    failure: function() {}
                });
                options.success = function(response)
                {
                    busy = false;
                    self.setTitle(self.name);
                    options.success(response);
                };
                options.failure = function(response)
                {
                    busy = false;
                    self.setTitle(self.name);
                    options.failure(response);
                };
                BaseJS.request(options);
                return true;
            };

            return {
                isBusy: isBusy,
                get: get,
                post: post,
                request: request
            };
        })();

        //Object for managing track syndication
        this.Syndicator = (function()
        {
            //Track syndication
            var syndication = null;
            var syndicated = false;
            var busy = false;

            //Determine if the track has been syndicated
            function check()
            {
                return syndicated;
            };

            //Get the track's syndication object
            function get()
            {
                return syndication;
            };

            //Syndicate the track
            function syndicate(options)
            {
                if (busy) return;
                busy = true;
                self.setTitle('Syndicating...');
                self.maskFrame("<span class='waiting'>Syndicating datasource...</span>");

                var options = Ext.applyIf(options || {},
                {
                    url: self.data,
                    success: function() {},
                    failure: function() {}
                });
                var tempS = options.success;
                var tempF = options.failure;

                options.success = function(response)
                {
                    syndicated = true;
                    syndication = response;
                    busy = false;

                    if (self.name == 'Track')
                    {
                        self.name = syndication.service.title;
                    }
                    self.setTitle(self.config.name);
                    //self.unmask();
                    tempS(response);
                };
                options.failure = function(string)
                {
                    syndication = {};
                    syndicated = false;
                    busy = false;
                    self.setTitle('Error: syndication failed');
                    self.unmaskFrame();
                    tempF(string);
                };
                BaseJS.syndicate(options);
            };

            return {
                isSyndicated: check,
                getSyndication: get,
                syndicate: syndicate
            };
        })();
    }
});