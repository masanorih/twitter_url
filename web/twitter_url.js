(function (global) {
  "use strict";
  var twitter_url = angular.module('twitter_url', []);
  twitter_url.controller('Ctrl', function($scope, $http, $window, $document) {
    // keyboard shortcuts
    $document.bind('keypress', function(ev) {
      //console.log(ev.which);
      if ( 82 == ev.which ) {      // 'R'
        $scope.load_url_list();
      }
      else if ( 80 == ev.which ) { // 'P'
        $scope.pass_all();
      }
      else if ( 74 == ev.which ) { // 'J'
        $scope.mv_target(1);
      }
      else if ( 75 == ev.which ) { // 'K'
        $scope.mv_target(-1);
      }
      else if ( 79 == ev.which ) { // 'O'
        var elem = $scope.url_list[$scope.target];
        $scope.go(elem);
      }
    })
    // controller methods
    // load url_list json data
    $scope.load_url_list = function() {
      var height = $window.innerHeight;
      var status = $scope.show_saved;
      $scope.height = height;
      var post_data = {
        height: height,
        status: status
      };
      $http.post('/turl/list', post_data).success(function(data) {
          $scope.url_list = data;
          $scope.hilight_target();
      });
      $http.post('/turl/count', post_data).success(function(data) {
          $scope.url_count = data.count;
      });
    }
    $scope.pass_all = function() {
      var ids = new Array;
      for(var idx in $scope.url_list) {
        var elem = $scope.url_list[idx];
        var id   = elem.id;
        elem.show_inprogress = "passing...";
        ids.push(id);
      }
      var post_data = {
        ids: ids
      };
      $http.post('/turl/mdelete', post_data).success(function(data) {
        $scope.load_url_list();
      });
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
        }).error(function(data, status, headers, config) {
            var string = "data<br>";
            string = JSON.stringify(data);
            string += "<br>status<br>";
            string += JSON.stringify(status);
            elem.show_inprogress = string;
        });
    }
    // simply delete entry
    $scope.save = function(elem) {
        var id  = elem.id;
        elem.show_inprogress = "saving...";
        $http.post('/turl/save?id=' + id).success(function(data) {
            delete_id(id);
            delete elem.show_inprogress;
        });;
    }
    // insert new entry
    $scope.insert_new_url = function() {
      var url = $scope.new_url;
      $http.post('/turl/insert', {url: url}).success(function(data) {
        $scope.new_url = '';
      });
    }
    // hilight target
    $scope.hilight_target = function() {
      for(var idx in $scope.url_list) {
        var elem = $scope.url_list[idx];
        if ( idx == $scope.target ) {
          elem.target = true;
          //console.log('idx ', idx, 'is true');
        }
        else {
          elem.target = false;
          //console.log('idx ', idx, 'is false');
        }
      }
    }
    // move target
    $scope.mv_target = function(i) {
      $scope.target += i;
      var max = $scope.url_list.length - 1;
      if ( $scope.target < 0 ) {
        $scope.target = 0;
      }
      else if ( $scope.target > max ) {
        $scope.target = max;
      }
      $scope.$apply(function() {
        $scope.hilight_target();
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

    // set default value
    $scope.target = 0;
    $scope.show_saved = 'list';
    $scope.load_url_list();
  });
})(this);
