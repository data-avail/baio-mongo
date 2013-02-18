#Baio-mongo.js 1.0.2
#
#http://github.com/data-avail/baio-mongo
#
#2013 Max Putilov, Data-Avail
#
#Baio-mongo may be freely distributed under the MIT license.
#
#The set of atomic operations to deal with native mongodb driver.
connection = require "./connection"
mongodb = require "mongodb"
_ = require "underscore"
async = require "async"
_config = null


# ##Public API##

#**setConfig (config)**
#
# Setup connection options for mongodb, should be invoked before any operation.
#
#@parameters
#
#* `config {Object}` conatins following fields
#
#   + `uri {string}` - connection string, if this field defined all other fields will be populeted from it. Example: `'pass:username@host:port/db'`
#   + `database {string}` - name of the database
#   + `host {string}` - server host
#   + `port {int}`  - server port
#   + `user {string}` - authentictaion user (if neccessary)
#   + `pass {string}` - authentictaion password (if neccessary)

setConfig = (config) ->
  _config = config

#**insert (table, item, [autoMap], done)**
#
# Insert new item into collection.
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `item {object}` - object to insert into collection
#* `autoMap {boolean}` (optional) - if `autoMap = true` or  `missed` then `_id` fields (`ObjectId` type) of newly
# created document will be converted to `id` field of type `string`
#* `@param done {function(err, docs)}` - callback function, where `doc` document which has been created, `id` filed of
# this document will be initalized. This object and `item` parameter is the same object.

insert = (table, item, autoMap, done) ->
  params = _muteParams2 autoMap, done
  async.waterfall [
    (ck) ->
      open table, ck
    (coll, ck) ->
      if params.opts
        ins = _.extend {}, item
        ins._id = item.id
        delete ins.id
      coll.insert item, safe : true, (err, doc) ->
        close coll
        ck err, doc
  ], (err, res) ->
    if !err and res
      _.extend true, item, res
      _mapItems err, params.opts, item
    params.callback err, item


#**get (table, filter, [select], [autoMap], done)**
#
# Read items from table (collection) as an array
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `filter {object}` - filter in mongodb query format
#* `select {object}` (optional) - fields selector in mongodb query format
#* `autoMap {boolean}` (optional) - if `autoMap = true` or  `missed` then `_id` fields (`ObjectId` type) of each
# retrieved document will be converted to `id` field of type `string`
#* `done {function(err, docs)}` - callback function, where `docs` retrieved documents
get = (table, filter, select, autoMap, done) ->
  params = _muteParams3 select, autoMap, done
  async.waterfall [
    (ck) ->
      open table, ck
  ,(coll, ck) ->
      coll.find(filter, params.obj).toArray (err, items) ->
        close coll
        ck err, items
  ], (err, items) ->
    _mapItems err, params.opts, items
    params.callback err, items


#**getSingle (table, filter, [select], [autoMap], done)**
#
# Reads single item
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `filter {object}` - filter in mongodb query format
#* `select {object}` (optional) - fields selector in mongodb query format
#* `autoMap {boolean}` (optional) - if `autoMap = true` or  `missed` then `_id` fields (`ObjectId` type) of each
# retrieved document will be converted to `id` field of type `string`
#* `done {function(err, doc)}` - callback function, where `doc` retrieved document, if several was found returns first one.
getSingle = (table, filter, select, autoMap, done) ->
  params = _muteParams3 select, autoMap, done
  get table, filter, params.obj, params.opts, (err, items) ->
    params.callback err, if err then null else items[0]


#**getById (table, id, [select], [autoMap], done)**
#
# Read single item by id
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `id {string}` - id in `string` format
#* `select {object}` (optional) - fields selector in mongodb query format
#* `autoMap {boolean}` (optional) - if `autoMap = true` or  `missed` then `_id` fields (`ObjectId` type) of each
# retrieved document will be converted to `id` field of type `string`
#* `done {function(err, doc)}` - callback function, where `doc` retrieved document
getById = (table, id, select, autoMap, done) ->
  params = _muteParams3 select, autoMap, done
  getSingle table, {_id : new mongodb.ObjectID id}, params.obj, params.opts, params.callback

#**remove (table, filter, done)**
#
# Remove items by filter
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `filter {object}` - filter in mongodb query format
#* `done {function(err)}` - callback function
remove = (table, filter, done) ->
  async.waterfall [
    (ck) ->
      open table, ck
    (coll, ck) ->
      coll.remove filter, (err) ->
        close coll
        ck err
  ], done

#**removeById (table, id, done)**
#
# Remove item by id
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `id {string}` - id in `string` format
#* `done {function(err)}` - callback function
removeById = (table, id, done) ->
  remove table, {_id : new mongodb.ObjectID id}, done

#**updateById (table, id, item, [isJustFields], done)**
#
# Update particular fields of the item
#
#@parameters
#
#* `table {string}` name of table (collection) to connect to
#* `id {string}` - id in `string` format
#* `item {object}` - item's fields to update, before update from item will be excluded `id` and `_id` fields
#* `isJustFields {boolean} (optional)` - if `item` parameter contains real mongodb operation such as $set, $unset, etc then this field should be `false`,
# if this parameter is just set of fields to upadte then this field should be `true` or `missed`.
#* `done {function(err)}` - callback function
updateById = (table, id, item, isJustFields, done) ->
  params = _muteParams2 isJustFields, done
  async.waterfall [
    (ck) ->
      open table, ck
    (coll, ck) ->
      updItem = _.extend {}, item
      if params.opts
        delete updItem.id
        delete updItem._id
      coll.update {_id : new mongodb.ObjectID id},(if params.opts then {$set : updItem} else item), {multi : false, safe : true, upsert : false}, (err) ->
        close coll
        ck err
  ], params.callback

# ##Private API##

_mapItems = (err, autoMap, items) ->
  if !err and autoMap
    items = [items] if !_.isArray items
    for item in items
      item.id = item._id.toHexString()
      delete item._id

_muteParams2 = (opts, callback) =>
  params = {}
  if _.isFunction opts
    params.callback = opts
    params.opts = true
  else
    params.callback = callback
    params.opts = if opts == false then false else true
  params

_muteParams3 = (obj, opts, callback) =>
  params = {}
  if _.isFunction obj
    params.callback = obj
    params.obj = {}
    params.opts = true
  else if _.isFunction opts
    if _.isBoolean obj
      params.callback = opts
      params.obj = {}
      params.opts = obj
    else
      params.callback = opts
      params.obj = if obj then obj else {}
      params.opts = true
  else
    params.callback = callback
    params.obj = if obj then obj else {}
    params.opts = opts
  params


#  Returns connection config structure, convert uri string if neccessary.
#
#     @return - connection parameters see setConfig
#
getConfig = ->
  if _config and _config.uri
    connection.str2config _config.uri
  else
    _config

#  Open db connection to particular table
open = (table, done) ->
  config = getConfig()
  if !config
    done new Error "config not initialized"
    return
  db = new mongodb.Db config.database, new mongodb.Server(config.host, config.port), w : 1
  async.waterfall [
    (ck) =>
      db.open ck
  ,(d, ck) =>
      if config.user
        db.authenticate config.user, config.pass, ck
      else
        ck null, null
  ,(f, ck) =>
      db.collection table, ck
  ], done


# Close connection, if not null. Skip otherwice.
close = (coll) ->
  if coll
    coll.db.close()

exports.setConfig = setConfig
exports.insert = insert
exports.get = get
exports.getSingle = getSingle
exports.getById = getById
exports.remove = remove
exports.removeById = removeById
exports.updateById = updateById



