'use strict';

app.factory('User', function ($resource) {

    var resource = $resource('/users', { },
      {      
        get: {
          method: 'GET',
          isArray: true
        }
  	  });

    return {

        allUsers: function(callback) {
            var cb = callback || angular.noop;
            return resource.get({ },
            function(data) {
                return cb(data);
            }, 
            function(err) {
                return cb(err);
            }).$promise;
        },
        createUser: function(user, callback) {
            var cb = callback || angular.noop;
            return resource.save(user, 
            function(data) {
                return cb(data);
            }, 
            function(err) {
                return cb(err);
            }).$promise;
        }

    }

});
