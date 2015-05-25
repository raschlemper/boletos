/**
 * Populate DB with sample data on server start
 * to disable, edit config/environment/index.js, and set `seedDB: false`
 */

'use strict';

var path = require('path');
var fs = require("fs");
var config = require('../config/environment');

var json = function() {

    var readJsonFileSync = function(filepath, encoding) {
        if (typeof(encoding) == 'undefined') {
            encoding = 'utf8';
        }
        var file = fs.readFileSync(filepath, encoding);
        return JSON.parse(file);
    };

    var getConfig = function(file) {
        var filepath = path.join(config.root, 'json', file);
        return this.readJsonFileSync(filepath);
    };

    return {
    	readJsonFileSync: readJsonFileSync,
    	getConfig: getConfig
    }


}();

/*
 * Insert users
 */
require('./userMock')(json);
