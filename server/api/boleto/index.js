'use strict';

var express = require('express');
var controller = require('./bb.controller');

var router = express.Router();

router.post('/bb/', controller.index);

module.exports = router;
