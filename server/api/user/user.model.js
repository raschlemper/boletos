'use strict';

var mongoose = require('mongoose');

var Schema = mongoose.Schema;

var UserSchema = new Schema({
  name: String,
  email: { type: String, lowercase: true },
  role: { type: String, default: 'user' },
  hashedPassword: String,
  image: String,
  provider: String
});


/**
 * Virtuals
 */
UserSchema
  .virtual('data')
  .get(function() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'image': image
    }
  });


/**
 * Validations
 */


/**
 * Pre-save hook
 */


/**
 * Methods
 */
UserSchema.methods = {
};

module.exports = mongoose.model('User', UserSchema);
