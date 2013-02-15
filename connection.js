//https://github.com/LearnBoost/mongoose/blob/master/lib/connection.js
var url = require("url");

exports.str2config = function (str) {
    var uri, host;

    config =
    {
        host : null,
        port : null,
        database : null,
        user : null,
        pass : null
    };

    options = {};

    uri = url.parse(str);
    config.host = uri.hostname;
    config.port = uri.port || 27017;
    config.database = uri.pathname && uri.pathname.replace(/\//g, '');
    host = config.host;

    if (!config.host) {
        callback(new Error('Missing connection hostname.'));
        return this;
    }

    if (!config.database) {
        callback(new Error('Missing connection database.'));
        return this;
    }

    // handle authentication
    if (uri && uri.auth) {
        var auth = uri.auth.split(':');
        config.user = auth[0];
        config.pass = auth[1];

        // Check hostname for user/pass
    } else if (/@/.test(host) && /:/.test(host.split('@')[0])) {
        host = host.split('@');
        var auth = host.shift().split(':');
        host = host.pop();
        config.user = auth[0];
        config.pass = auth[1];

        // user/pass options
    } else if (options && options.user && options.pass) {
        config.user = options.user;
        config.pass = options.pass;

    } else {
        config.user = config.pass = undefined;
    }

    if (config.port){
        config.port = parseInt(config.port);
    }


    return config;
};