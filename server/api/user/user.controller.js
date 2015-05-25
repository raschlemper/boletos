'use strict';

var User = require('./user.model');

/**
 * Get list of users
 * restriction: 'admin'
 */
exports.index = function(req, res) {
  User.find({}, function (err, users) {
    if(err) return res.send(500, err);
    res.json(200, users);
  });
};

/**
 * Create user
 */
exports.create = function(req, res, next) {
  var newUser = new User(req.body);
  newUser.save(function(err, user) {
  	if(err) return res.send(500, err);
    res.json(200, req.user);
  });
};
