'use strict';

var app = angular.module('teratecBoletoApp', [
    'ngAnimate',
    'ngCookies',
    'ngResource',
    'ngSanitize',
    'ngTouch',
    'ui.router',
    'ui.bootstrap'
  ])
  .config(function ($urlRouterProvider, $stateProvider) {

    $urlRouterProvider
      .otherwise('/');

    $stateProvider
      .state('main', {
        url: '/',
        templateUrl: 'view/boleto.html',
        controller: 'BoletoCtrl'
      });
  
  })
