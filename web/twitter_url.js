(function (global) {
  "use strict";
  var twitter_url = angular.module('twitter_url', []);
  twitter_url.controller('Ctrl', function($scope, $http, $window) {
    // load url_list json data
    $scope.load_url_list = function() {
      var width = $window.innerWidth;
      $http.get('/turl/list?width=' + width).success(function(data) {
          $scope.url_list = data;
      });
      $http.get('/turl/count').success(function(data) {
          $scope.url_count = data[0].count;
      });
    }
    // controller methods
    $scope.go = function(elem) {
      var id  = elem.id;
      var url = elem.url;
      $http.post('/turl/delete?id=' + id).success(function(data) {
          delete_url_list(id);
      });
      window.open(url);
    }
    // simply delete entry
    $scope.pass = function(elem) {
      var id  = elem.id;
      elem.show_deleting = "deleting...";
      $http.post('/turl/delete?id=' + id).success(function(data) {
          delete_url_list(id);
          delete elem.show_deleting;
      });
    }

    function get_idx(id) {
      for(var idx in $scope.url_list) {
        var elem = $scope.url_list[idx];
        if (id == elem.id) {
          return idx;
        }
      }
      return false;
    }
    function delete_url_list(id) {
      var idx = get_idx(id);
      if (idx) {
        $scope.url_list.splice(idx, 1);
        if ($scope.url_count) {
          $scope.url_count--;
        }
      }
      if(2 >= $scope.url_list.length) {
        $scope.load_url_list();
      }
    }

    $scope.load_url_list();
  });
})(this);
