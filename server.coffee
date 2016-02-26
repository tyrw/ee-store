switch process.env.NODE_ENV
  when 'production'
    require 'newrelic'
  when 'test'
    process.env.PORT = 4444
  else
    process.env.NODE_ENV = 'development'
    process.env.PORT = 4000

express       = require 'express'
morgan        = require 'morgan'
path          = require 'path'
serveStatic   = require 'serve-static'
cookieParser  = require 'cookie-parser'
ejs           = require 'ejs'
compression   = require 'compression'
_             = require 'lodash'
constants     = require './server.constants'
utils         = require './models/utils'

User          = require './models/user'
Product       = require './models/product'
Collection    = require './models/collection'
Sku           = require './models/sku'
Cart          = require './models/cart'

app = express()
app.use compression()

app.set 'view engine', 'ejs'
app.set 'views', path.join __dirname, 'dist'

if process.env.NODE_ENV is 'production' then app.use morgan 'common' else app.use morgan 'dev'

app.use serveStatic(path.join __dirname, 'dist')
app.use cookieParser()

cartCookie = (req, res, next) ->
  if req.cookies and req.cookies.cart
    [ee, cart_id, uuid] = req.cookies.cart.split('.')
    if !cart_id or !uuid then return next()
    Cart.findByIdAndUuid cart_id, uuid
    .then (data) -> req.cart = data[0]
    .catch (err) -> console.log 'Error in cartCookie', err
    .finally () -> next()
  else
    next()

app.use cartCookie

# HOME
app.get '/', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  # TODO finish new meta images
  .then () -> User.setCollectionMetaImages bootstrap
  .then () -> Product.sort { id: bootstrap.id }, { page: bootstrap.page, feat: true }
  .then (data) ->
    { rows, count } = data
    bootstrap.products    = rows || []
    bootstrap.count       = count
    bootstrap.stringified = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    # TODO add better error pages
    console.error 'error in HOME', err
    res.send 'Not found'

# ABOUT
app.get ['/about'], (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () ->
    bootstrap.stringified = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    # TODO add better error pages
    console.error 'error in ABOUT', err
    res.redirect '/'

# PRODUCT
app.get '/products/:id/:title*?', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () -> Product.findCompleteById req.params.id, bootstrap.id
  .then (product) ->
    bootstrap.product     = product
    bootstrap.title       = bootstrap.product.title
    bootstrap.images      = utils.makeMetaImages([ bootstrap.product?.image ])
    bootstrap.description = bootstrap.product.content
    bootstrap.stringified = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in PRODUCTS', err
    res.redirect '/'

# COLLECTION
app.get '/collections/:id/:title*?', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () -> Product.findAllByCollection { id: bootstrap.id }, { page: bootstrap.page, order: bootstrap.order, range: bootstrap.range, collection_id: req.params.id }
  .then (data) ->
    { collection, rows, count } = data
    bootstrap.collection    = collection
    bootstrap.products      = rows || []
    bootstrap.count         = count
    bootstrap.title         = utils.formCollectionPageTitle bootstrap.collection.title, bootstrap.title
    bootstrap.images        = utils.makeMetaImages(_.pluck(bootstrap.products.slice(0,3), 'image'))
    bootstrap.stringified   = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in COLLECTIONS', err
    res.redirect '/'

# COLLECTIONS
app.get '/collections', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () -> Collection.findAll bootstrap.id
  .then (data) ->
    bootstrap.collections   = data
    # bootstrap.count         = count
    # bootstrap.title         = utils.formCollectionPageTitle bootstrap.collection.title, bootstrap.title
    # bootstrap.images        = utils.makeMetaImages(_.pluck(bootstrap.products.slice(0,3), 'image'))
    bootstrap.stringified   = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in COLLECTIONS', err
    res.redirect '/'

# CATEGORY
app.get '/categories/:id/:title*?', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () ->
    [min_price, max_price] = utils.rangeToPrices bootstrap.range
    Product.sort { id: bootstrap.id }, { page: bootstrap.page, order: bootstrap.order, min_price: min_price, max_price: max_price, category_ids: '' + req.params.id }
  .then (data) ->
    { collection, rows, count } = data
    bootstrap.collection    = collection
    bootstrap.products      = rows || []
    bootstrap.count         = count
    # bootstrap.title         = utils.formCollectionPageTitle bootstrap.collection.title, bootstrap.title
    bootstrap.images        = utils.makeMetaImages(_.pluck(bootstrap.products.slice(0,3), 'image'))
    bootstrap.stringified   = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in CATEGORIES', err
    res.redirect '/'

# HELP
app.get '/help', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () ->
    bootstrap.stringified = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in HELP', err
    res.redirect '/'

# SEARCH
app.get '/search', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () ->
    opts =
      size:   bootstrap.perPage
      search: bootstrap.query
      page:   bootstrap.page
    # if bootstrap.query  then opts.search  = bootstrap.query
    # if bootstrap.page   then opts.page    = bootstrap.page
    Product.search { id: bootstrap.id }, opts
  .then (data) ->
    bootstrap.products = data.rows
    bootstrap.count = data.count
    bootstrap.page = data.page
    bootstrap.perPage = data.perPage
    bootstrap.stringified = utils.stringify bootstrap
    res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in SEARCH', err
    res.redirect '/'

# CART
app.get '/cart', (req, res, next) ->
  { bootstrap, host, path } = utils.setup req
  User.defineStorefront host, bootstrap
  .then () ->
    if req.cart and req.cart.quantity_array and req.cart.quantity_array.length > 0
      sku_ids = _.pluck req.cart.quantity_array, 'sku_id'
      Sku.forCart sku_ids.join(','), bootstrap.id
      .then (data) -> bootstrap.cart.skus = data
      .finally () ->
        bootstrap.stringified = utils.stringify bootstrap
        res.render 'store.ejs', { bootstrap: bootstrap }
    else
      bootstrap.stringified = utils.stringify bootstrap
      res.render 'store.ejs', { bootstrap: bootstrap }
  .catch (err) ->
    console.error 'error in CART', err
    res.redirect '/'

# SITEMAP
app.get ['/sitemap', '/sitemap.xml'], (req, res, next) ->
  { bootstrap, protocol, host, path } = utils.setup req
  User.defineSitemap protocol, host, bootstrap
  .then (entries) ->
    res.setHeader 'content-type', 'text/xml'
    res.render 'sitemap.ejs', { entries: entries }
  .catch (err) ->
    console.error 'error in SITEMAP', err
    res.redirect '/'

# LEGACY REDIRECTS
app.get ['/selections/:id/:title', '/shop', '/shop/:title'], (req, res, next) ->
  res.redirect '/'

app.listen process.env.PORT, ->
  console.log 'Store app listening on port ' + process.env.PORT
  return
