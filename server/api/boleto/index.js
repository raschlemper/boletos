'use strict';

var express = require('express');
var controller = require('./bb.controller');

var router = express.Router();

router.get('/bb/', controller.index);

module.exports = router;
