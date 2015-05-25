app.directive( 'appHref', function ( $location ) {
  return function ( scope, element, attrs ) {
    var path;

    attrs.$observe( 'appHref', function (val) {
      path = val;
    });

    element.bind( 'click', function () {
      scope.$apply( function () {
        $location.path( path );
      });
    });
  };
});