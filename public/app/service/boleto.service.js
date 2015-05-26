'use strict';

app.factory('Boleto', function($http, $q) {

    return {

        get: function(dadosBoleto, callback) {
            var cb = callback || angular.noop;
            var deferred = $q.defer();
            $http.post('/boleto/bb/', dadosBoleto)
                .success(function(data) {
                    deferred.resolve(data);
                    return cb();
                }).error(function(err) {
                    deferred.reject(err);
                    return cb(err);
                }.bind(this));

            return deferred.promise;

        }

    };

});
