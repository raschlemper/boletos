/**
 * MongoDB Configuration
 */

'use strict';

var mongoose = require('mongoose');
var config = require('./environment');

// Connect to database
mongoose.connect(config.mongo.uri, config.mongo.options);

// Populate DB with sample data
if(config.seedDB) { require('../mock/'); }
