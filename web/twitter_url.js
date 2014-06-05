(function (global) {
  "use strict";
  var twitter_url = angular.module('twitter_url', []);
  twitter_url.controller('Ctrl', function($scope, $http, $window, $document) {
    // keyboard shortcuts
    $document.bind('keypress', function(ev) {
      if (false == $scope.focus_new_url) {
        //console.log(ev.which);
        if (114 == ev.which) {      // 'r'
          $scope.load_url_list();
        }
        else if (112 == ev.which) { // 'p'
          $scope.target = 0;
          $scope.pass_all();
        }
        else if (106 == ev.which) { // 'j'
          $scope.mv_target(1);
        }
        else if (107 == ev.which) { // 'k'
          $scope.mv_target(-1);
        }
        else if (111 == ev.which) { // 'o'
          var elem = $scope.url_list[$scope.target];
          $scope.mv_target(-1);
          $scope.go(elem);
        }
      }
    })
    // controller methods
    // load url_list json data
    $scope.load_url_list = function(next) {
      var height = $window.innerHeight;
      var status = $scope.show_saved;
      $scope.height = height;
      var post_data = {
        height: height,
        status: status
      };
      if(next && $scope.url_list) {
        var last_id;
        for(var idx in $scope.url_list) {
          last_id = $scope.url_list[idx].id;
        }
        post_data.nextid = last_id;
      }
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
      var userAgent = $window.navigator.userAgent;
      if (userAgent.match(/chrome/i)) {
        openNewBackgroundTab(url);
      }
      else {
        window.open(url);
      }
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
    // via http://stackoverflow.com/questions/10812628/open-a-new-tab-in-the-background
    function openNewBackgroundTab(url){
      var a = document.createElement("a");
      a.href = url;
      var evt = document.createEvent("MouseEvents");
      // the tenth parameter of initMouseEvent sets ctrl key
      evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0,
                                  true, false, false, false, 0, null);
      a.dispatchEvent(evt);
    }

    // set default value
    $scope.target = 0;
    $scope.show_saved = 'list';
    $scope.load_url_list();
    $scope.focus_new_url = false;
  });
})(this);
