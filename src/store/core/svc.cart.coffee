'use strict'

angular.module('store.core').factory 'eeCart', ($rootScope, $state, $cookies, eeBack) ->
  ## Format of cart:
  # _data = {
  #   calc_meta: {
  #     product_total: int
  #     shipping_total: int
  #     tax_total: int
  #     grand_total: int
  #   },
  #   entries: [
  #     { product: product, quantity: int },
  #     { product: product, quantity: int },
  #     { product: product, quantity: int }
  #   ]
  # }

  ## SETUP
  # _data =
    # calc_meta: {}
    # entries: []

  ## PRIVATE FUNCTIONS
  # _calcMeta = () ->
  #   count           = 0
  #   product_total   = 0
  #   shipping_total  = 0
  #   tax_total       = 0
  #   grand_total     = 0
  #   addToTotals = (entry) ->
  #     product_total   += parseInt(parseInt(entry.product.calculated.selling_price) * parseInt(entry.quantity))
  #     shipping_total  += parseInt(parseInt(entry.product.shipping_price) * parseInt(entry.quantity))
  #     count           += parseInt(entry.quantity)
  #   addToTotals(cart_entry) for cart_entry in _data.entries
  #   grand_total = product_total + shipping_total + tax_total
  #   _data.calc_meta =
  #     count:          count
  #     product_total:  product_total
  #     shipping_total: shipping_total
  #     tax_total:      tax_total
  #     grand_total:    grand_total
  #   return

  _addOrIncrement = (selection_id, quantity_array) ->
    quantity_array ||= []
    inArray = false
    for pair, i in quantity_array
      if parseInt(selection_id) is parseInt(pair.id)
        pair.quantity += 1
        inArray = true
    quantity_array.push { id: selection_id, quantity: 1 } unless inArray

  _remove = (selection_id, quantity_array) ->
    quantity_array ||= []
    temp = []
    for pair, i in quantity_array
      if parseInt(selection_id) isnt parseInt(pair.id) then temp.push quantity_array[i]
    temp

  _addSelection = (selection_id, quantity_array) ->
    _addOrIncrement selection_id, quantity_array
    if $cookies.cart
      [ee, cart_id, token] = $cookies.cart.split('.')
      eeBack.cartPUT cart_id, { quantity_array: quantity_array, token: token }
      .then (res) ->
        $cookies.cart = ['ee', res.id, res.uuid].join('.')
        $state.go 'cart'
      .catch (err) -> console.error err
    else
      eeBack.cartPOST quantity_array
      .then (res) ->
        $cookies.cart = ['ee', res.id, res.uuid].join('.')
        $state.go 'cart'
      .catch (err) -> console.error err

  _removeSelection = (selection_id, quantity_array) ->
    quantity_array = _remove selection_id, quantity_array
    [ee, cart_id, token] = $cookies.cart.split('.')
    eeBack.cartPUT cart_id, { quantity_array: quantity_array, token: token }
    .then (res) ->
      $cookies.cart = ['ee', res.id, res.uuid].join('.')
      $state.go 'cart', null, reload: true
    .catch (err) -> console.error err

  _updateCartTo = (quantity_array) ->
    quantity_array ||= []
    [ee, cart_id, token] = $cookies.cart.split('.')
    eeBack.cartPUT cart_id, { quantity_array: quantity_array, token: token }
    .then (res) ->
      $cookies.cart = ['ee', res.id, res.uuid].join('.')
      $state.go 'cart', null, reload: true
    .catch (err) -> console.error err


  ## EXPORTS
  # data: _data
  fns:
    addSelection: _addSelection
    removeSelection: _removeSelection
    updateCartTo: _updateCartTo

  # calculate: () -> _calcMeta(); return
  #
  # count: () -> _data.entries.length || 0
  #
  # addProduct: (product) ->
  #   increment = false
  #   addOrIncrement = (selection_id, entry) ->
  #     if !!selection_id && entry.product.selection_id is selection_id
  #       entry.quantity += 1
  #       increment = true
  #   addOrIncrement(product.selection_id, entry) for entry in _data.entries
  #   if increment is false then _data.entries.push { product: product, quantity: 1 }
  #   _calcMeta()
  #   eeModal.fns.close 'product'
  #   $state.go 'cart'
  #   return
  #
  # removeProduct: (product) ->
  #   newCart = { calc_meta: {}, entries: [] }
  #   removeIfMatch = (selection_id, n) ->
  #     entry = _data.entries[n]
  #     if !!entry && entry.product.selection_id isnt selection_id then newCart.entries.push entry
  #   removeIfMatch(product.selection_id, n) for n in [0..(_data.entries.length - 1)]
  #   _data.calc_meta = newCart.calc_meta
  #   _data.entries   = newCart.entries
  #   _calcMeta()
  #   console.log 'removed', _data
  #   return
  #
  # getProductNames: () ->
  #   names = []
  #   addName = (entry) -> names.push entry.product.title
  #   addName(entry) for entry in _data.entries
  #   names.join('; ')
  #
  # getSelectionIds: () ->
  #   ids = []
  #   addId = (entry) -> ids.push(entry.quantity + 'x' + entry.product.selection_id)
  #   addId(entry) for entry in _data.entries
  #   ids.join('; ')
