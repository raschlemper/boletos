/**
 * Express configuration
 */

'use strict';

var express = require('express');
var bodyParser = require('body-parser');
var config = require('./environment');
var path = require('path');

module.exports = function(app) {
  var env = app.get('env');
  app.use(bodyParser.json());
  
  if ('production' === env) {
    app.use(express.static(path.join(config.root, 'public')));
    app.set('appPath', config.root + '/public');
  }

  if ('development' === env || 'test' === env) {
    app.use(express.static(path.join(config.root, 'public')));
    app.set('appPath', config.root + '/public');
  }
};