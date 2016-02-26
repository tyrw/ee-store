Promise   = require 'bluebird'
_         = require 'lodash'
url       = require 'url'
sequelize = require '../config/sequelize/setup'
constants = require '../server.constants'
utils     = require './utils'

Collection = require './collection'

### IMPORTANT ###
# Users, Collections, and Orders should use
# 'deleted_at IS NULL' as part of query

User =

  storeByDomain: (host) ->
    sequelize.query 'SELECT id, tr_uuid, username, storefront_meta, collections FROM "Users" WHERE domain = ? AND deleted_at IS NULL', { type: sequelize.QueryTypes.SELECT, replacements: [host] }

  storeByUsername: (username) ->
    sequelize.query 'SELECT id, tr_uuid, username, storefront_meta, collections FROM "Users" WHERE username = ? AND deleted_at IS NULL', { type: sequelize.QueryTypes.SELECT, replacements: [username] }

  findByHost: (host) ->
    host  = host.replace 'www.', ''
    searchTerm  = host
    queryUser   = User.storeByDomain
    if process.env.NODE_ENV isnt 'production' or host.indexOf('eeosk.com') > -1 or host.indexOf('herokuapp.com') > -1 or host.indexOf('.demoseller.com') > -1
      username = 'demoseller' # 'stylishrustic'
      if host.indexOf('herokuapp.com') > -1 then username = 'stylishrustic' # 'demoseller'
      if host.indexOf('eeosk.com') > -1 or host.indexOf('.demoseller.com') > -1 then username = host.split('.')[0]
      searchTerm  = username
      queryUser   = User.storeByUsername
    queryUser searchTerm

  defineStorefront: (host, bootstrap) ->
    User.findByHost host
    .then (data) ->
      utils.assignBootstrap bootstrap, data[0]
      Collection.navCollectionsBySellerId bootstrap.id
    .then (collections) ->
      bootstrap.nav =
        carousel: collections
        # alphabetical: data.alphabetical
      bootstrap

  setCollectionMetaImages: (bootstrap) ->
    Collection.metaImagesFor bootstrap.id
    .then (images) ->
      if images and images.length > 0 then bootstrap.images = utils.makeMetaImages images

  defineSitemap: (protocol, host, bootstrap) ->
    baseLoc = protocol + '://' + host
    lastmod = utils.yyyymmdd()
    entries = [
      { loc: baseLoc, lastmod: lastmod, changefreq: 'weekly', priority: '1.0' }
      { loc: baseLoc + '/collections', lastmod: lastmod, changefreq: 'weekly', priority: '0.9' }
      { loc: baseLoc + '/help', lastmod: lastmod, changefreq: 'monthly', priority: '0.8' }
      { loc: baseLoc + '/search', lastmod: lastmod, changefreq: 'monthly', priority: '0.6' }
    ]
    User.findByHost host
    .then (data) ->
      user = data[0]
      if user.storefront_meta.about?.headline then entries.push { loc: baseLoc + '/about', lastmod: lastmod, changefreq: 'monthly', priority: '0.7' }
      Collection.findAll user.id
    .then (collections) ->
      for collection in collections
        entries.push { loc: baseLoc + '/collections/' + collection.id + '/', lastmod: lastmod, changefreq: 'weekly', priority: '0.9' }
      entries


module.exports = User
