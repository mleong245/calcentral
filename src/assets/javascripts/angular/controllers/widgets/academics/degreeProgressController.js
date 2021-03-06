'use strict';

var angular = require('angular');
var _ = require('lodash');

angular.module('calcentral.controllers').controller('DegreeProgressController', function(degreeProgressFactory, $scope) {

  $scope.degreeProgress = {
    graduate: {
      isLoading: true
    }
  };

  var loadDegreeProgress = function() {
    degreeProgressFactory.getDegreeProgress()
      .then(function(data) {
        $scope.degreeProgress.graduate.progresses = _.get(data, 'data.feed.degreeProgress');
        $scope.degreeProgress.graduate.links = _.get(data, 'data.feed.links');
        $scope.degreeProgress.graduate.errored = _.get(data, 'errored');
      })
      .finally(function() {
        $scope.degreeProgress.graduate.isLoading = false;
      });
  };

  loadDegreeProgress();
});
