(function (global) {
  "use strict";
  var twitter_url = angular.module('twitter_url', []);
  twitter_url.controller('Ctrl', function($scope, $http, $window) {
    // controller methods
    // load url_list json data
    $scope.load_url_list = function() {
      var width = $window.innerWidth;
      var status = $scope.show_saved;
      var post_data = {
        width: width,
        status: status
      };
      $http.post('/turl/list', post_data).success(function(data) {
          $scope.url_list = data;
      });
      $http.post('/turl/count', post_data).success(function(data) {
          $scope.url_count = data[0].count;
      });
    }
    $scope.pass_all = function() {
      for(var idx in $scope.url_list) {
        var elem = $scope.url_list[idx];
        $scope.pass(elem);
      }
    }
    $scope.change_status = function() {
        $scope.load_url_list();
        //console.log("show_saved = " + $scope.show_saved);
    }
    $scope.go = function(elem) {
      var id  = elem.id;
      var url = elem.url;
      $http.post('/turl/delete?id=' + id).success(function(data) {
          delete_id(id);
      });
      window.open(url);
    }
    // simply delete entry
    $scope.pass = function(elem) {
      var id  = elem.id;
      elem.show_inprogress = "passing...";
      $http.post('/turl/delete?id=' + id).success(function(data) {
          delete_id(id);
          delete elem.show_inprogress;
      });
    }
    // simply delete entry
    $scope.save = function(elem) {
      var id  = elem.id;
      elem.show_inprogress = "saving...";
      $http.post('/turl/save?id=' + id).success(function(data) {
          delete_id(id);
          delete elem.show_inprogress;
      });
    }
    // insert new entry
    $scope.insert_new_url = function() {
      var url = $scope.new_url;
      $http.post('/turl/insert', {url: url}).success(function(data) {
        $scope.new_url = '';
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
    function delete_id(id) {
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

    $scope.show_saved = 'list';
    $scope.load_url_list();
  });
})(this);
