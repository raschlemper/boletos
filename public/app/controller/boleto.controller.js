'use strict';

app.controller('BoletoCtrl', function ($scope, $http, Boleto) {
    
	Boleto.get()
		.then( function(data) {
            $scope.boleto = data;
            console.log($scope.boleto);
        })
        .catch( function() { });

});
