'use strict'

angular.module 'ee-storeproduct-for-storefront', []

angular.module('ee-storeproduct-for-storefront').directive "eeStoreproductForStorefront", () ->
  templateUrl: 'ee-shared/components/ee-storeproduct-for-storefront.html'
  restrict: 'E'
  scope:
    selection: '='
  link: (scope, ele, attr) ->
    return
