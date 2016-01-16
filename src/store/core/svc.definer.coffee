'use strict'

angular.module('store.core').factory 'eeDefiner', (eeUser, eeProducts, eeCollection, eeCollections) ->

  ## SETUP
  _exports =
    User:         eeUser.data
    Products:     eeProducts.data
    Collection:   eeCollection.data
    Collections:  eeCollections.data

  ## PRIVATE FUNCTIONS
  # none

  ## EXPORTS
  exports: _exports