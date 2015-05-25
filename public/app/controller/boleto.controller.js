'use strict';

app.controller('BoletoCtrl', function ($scope, $http, User) {

    $scope.users = [];

    $scope.pagination = { currentPage: 1, maxPerPage: 6 };
    $scope.list = { begin: function(currentPage) {
                        return $scope.pagination.maxPerPage * currentPage;
                    },
                    size: function(currentPage) {
                        var last = $scope.list.begin(currentPage) - $scope.users.length;
                        return -1 * ($scope.pagination.maxPerPage - last);
                    }
    };
    
	User.allUsers()
		.then( function(data) {
            $scope.users = data;
        })
        .catch( function() { });

    $scope.createUser = function() {
    	User.createUser($scope.user)
		    .then( function(data) {
                $scope.user = data;
            })
            .catch( function() { });
    }

});
