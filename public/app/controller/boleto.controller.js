'use strict';

app.controller('BoletoCtrl', function($scope, $http, Boleto) {

    var diasPrazoPagamento = 5;
    var taxaBoleto = 2.95;
    var valorCobrado = 2950.05;

    var getDadosBoleto = function() {
        return {
            diasPrazoPagamento: diasPrazoPagamento,
            taxaBoleto: taxaBoleto,
            valorCobrado: valorCobrado
        }
    }

    Boleto.get(getDadosBoleto())
        .then(function(data) {
            $scope.boleto = data;
            console.log($scope.boleto);
        })
        .catch(function() {});

});
