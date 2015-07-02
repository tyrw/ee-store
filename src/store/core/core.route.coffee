'use strict'

angular.module('store.core').config ($locationProvider, $stateProvider, $urlRouterProvider, $httpProvider) ->

  views =
    header:
      controller: 'storeCtrl as storefront'
      templateUrl: 'store/store.header.html'
    top:
      controller: 'storeCtrl as storefront'
      templateUrl: 'ee-shared/storefront/storefront.carousel.html'
    middle:
      controller: 'storeCtrl as storefront'
      templateUrl: 'ee-shared/storefront/storefront.products.html'
    footer:
      controller: 'storeCtrl as storefront'
      templateUrl: 'ee-shared/storefront/storefront.footer.html'

  shopViews =
    header: views.header
    top:    views.middle
    footer: views.footer

  aboutViews =
    header: views.header
    top:
      controller: 'storeCtrl as storefront'
      templateUrl: 'ee-shared/storefront/storefront.about.html'
    footer: views.footer

  data =
    pageTitle:        'Add products | eeosk'
    pageDescription:  'Choose products to add to your store.'
    padTop:           '51px'

  $stateProvider

    .state 'storefront',
      url:      '/'
      views:    views
      data:     data

    .state 'storefront-shop',
      url:      '/shop'
      views:    shopViews
      data:     data

    .state 'collection',
      url:      '/shop/:title'
      views:    shopViews
      data:     data

    .state 'storefront-about',
      url:      '/about'
      views:    aboutViews
      data:     data

    .state 'selectionView',
      url:      '/selections/:id/:slug'
      views:
        header:
          controller: 'storeCtrl as storefront'
          templateUrl: 'store/store.header.html'
        top:
          controller: 'selectionCtrl as storefront'
          templateUrl: 'store/store.selection.html'
        footer:
          controller: 'storeCtrl as storefront'
          templateUrl: 'ee-shared/storefront/storefront.footer.html'
      data: data,
      params:
        slug:
          value: null
          squash: true

    .state 'cart',
      url: '/cart'
      views:
        header: views.header
        top:
          controller:  'cartCtrl as cart'
          templateUrl: 'store/cart/cart.html'
        footer: views.footer
      data:
        padTop: '51px'

    .state 'cart-success',
      url: '/cart/success'
      views:
        header: views.header
        top:
          controller:  'cartCtrl as cart'
          templateUrl: 'store/cart/success.html'
        footer: views.footer
      data:
        padTop: '51px'

  $urlRouterProvider.otherwise '/'
  return
