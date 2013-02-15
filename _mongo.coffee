mongodb = require "mongodb"
async = require "async"
Db = mongodb.Db
conn = require "./connection"
_ = require "underscore"


class MongoDb

  constructor: (@config) ->
    if typeof @config == "string"
      @config = conn.str2config @config
    Server = mongodb.Server;
    @db = new Db @config.database, new Server(@config.host, @config.port), w : 1
    @collection = null

  open: (table, onDone) ->
    @openCollection table, (err, coll) =>
      @collection = coll
      if onDone then onDone err, coll

  openCollection: (table, onDone)->
    async.waterfall [
      (ck) =>
        @db.open ck
    ,(d, ck) =>
        if @config.user
          d.authenticate @config.user, @config.pass, ck
        else
          ck null, null
    ,(f, ck) =>
        if table
          @iniCollection table, ck
        else ck()
    ],
      (err, coll) =>
        if onDone then onDone err, coll

  iniCollection : (table, onDone) ->
    @db.collection table, (err, collection) =>
      if onDone then onDone err, collection

  close: ->
    @db.close()

  _iniCollection : (table, onDone) ->
    @db.collection table, (err, collection) =>
      if !err then @collection = collection
      if onDone then onDone err, collection

  @GetById: (config, table, id, onDone) ->
    MongoDb.GetSingle config, table, {id : id}, onDone

  @GetSingle: (config, table, filter, onDone) ->
    MongoDb.SelectSingle config, table, filter, {}, onDone

  @SelectSingle: (config, table, filter, select, onDone) ->
    MongoDb.SelectBatch config, table, filter, select, (err, data) ->
      if !err and data then data = data[0]
      onDone err, data

  @ReadBatch: (config, table, filter, onDone) ->
    MongoDb.SelectBatch config, table, filter, {}, onDone

  @SelectBatch: (config, table, filter, select, onDone) ->
    db = new MongoDb config
    async.waterfall [
      (ck) ->
        db.open table, ck
    ,(coll, ck) ->
        db.readBatch filter, select, ck
    ], (err, items) ->
      db.close()
      onDone err, items

  readBatch: (filter, select, onDone) ->
    if _.isFunction select
      onDone = select
      select = {}
    @collection.find filter, select, (err, cusror) ->
      res = []
      cusror.each (err, item) ->
        if !err and item
          res.push item
        else
          onDone err, res

  read: (filter, onIter, onDone) ->
    @collection.find filter, (err, cusror) ->
      cusror.each (err, item) ->
        if item
          onIter err, item
        else
          onDone err

  readNext: (filter, onNext) ->
    @collection.find filter, (err, cusror) ->
      if !err
        cusror.nextObject onNext
      else
        onNext err

  find: (filter, onDone) ->
    @collection.find filter, onDone

  count: (filter, onDone) ->
    @collection.count filter, onDone

  #update item (or create new if not exists), items - one or array
  update: (items, onDone) ->
    MongoDb.Update @collection, items, onDone

  @Update: (coll, items, onDone) ->
    errs = []
    items = [items] if !Array.isArray items
    async.forEach items
      , (item, ck) ->
        coll.update {_id : item._id}, item, {safe : true, multi : false, upsert : true }, (err, docs) ->
          if err
            #log.debug code : "data_update", err : err
            errs.push err
          ck()
      , ->
        if onDone then onDone (if errs.length then errs else null)

  #insert item (if exists nothing happens)
  insert: (items, onDone) ->
    MongoDb.Insert @collection, items, onDone

  @Insert: (coll, items, onDone) ->
    #console.log items
    errs = []
    items = [items] if ! Array.isArray items
    #bulk insert fails when first error arised
    async.forEach items
      , (item, ck) ->
        coll.insert item, safe : true, (err, docs) ->
          if err
            #log.debug code : "data_insert", err : err, item : item
            errs.push err
          ck()
      , ->
        if onDone then onDone (if errs.length then errs else null)
  ###
  coll.insert items, safe : true,  (err, docs) =>
    if err then log.warn code : "data_insert", err : err
    if onDone then onDone err
  ###

  #update item (or create new if not exists), items - one or array
  insertIfUpdate: (items, insert, onDone) ->
    MongoDb.InsertIfUpdate @collection, items, insert, onDone

  @InsertIfUpdate: (coll, items, insert, onDone) ->
    errs = []
    items = [items] if !Array.isArray items
    async.forEach items
      ,(item, cb) ->
        async.waterfall [
          (ck) ->
            coll.insert i, {safe : true}, (err) ->
              if err and err.message.indexOf('E11000 ') != -1
                ck null, false
              else
                ck err, true
          (isIns, ck) ->
            if !isIns
              id = item["_id"]
              delete item["_id"]
              coll.update {_id : id}, {$set : item}, {multi : false, safe : true, upsert : false}, ck
            else
              ck()
        ], (err) ->
          #log.debug code : "data_update", err : err
          if err then errs.push err
          cb()
      , -> if onDone then onDone (if errs.length then errs else null)

  @InsertWithFilter: (config, table, items, onFilter, onDone) ->
    db = new MongoDb config
    async.waterfall [
      (ck) ->
        db.open table, ck
    ,(coll, ck) ->
        db.insertWithFilter items, onFilter, ck
    ], (err, items) ->
      db.close()
      onDone err, items

  insertWithFilter: (items, onFilter, onDone) ->
    errs = []
    items = [items] if !Array.isArray items
    async.forEach items
      ,(item, ck) =>
        fr = onFilter(item)
        @collection.count fr, (err, count) =>
          if !count
            @insert item, ck
          else
            ck()
      , onDone

  @Ins: (config, table, item, autoMap, callback) ->
    db = new MongoDb config
    async.waterfall [
      (ck) ->
        db.open table, ck
      (coll, ck) ->
        if autoMap
          ins = _.extend {}, item
          ins._id = item.id
          delete ins.id
        db.insert ins, ck
    ], (err, res) ->
      db.close()
      if !err and autoMap
        _.extend item, res
        item.id = item._id
        delete item._id
      callback err, item

  @Upd: (config, table, filter, item, callback) ->
    db = new MongoDb config
    async.waterfall [
      (ck) ->
        db.open table, ck
      (coll, ck) ->
        coll.find filter, {_id : 1}, ck
      (cursor, ck) ->
        async.doWhilst(
          (item) -> item == null,
          ((cb) ->
            cursor.nextObject (err, doc) ->
              db.collection.update {_id : doc.id}, {$set : item}, {multi : false, safe : true, upsert : false}, cb),
          ck)
    ], (err) ->
      db.close()
      callback err

  @UpdById: (config, table, id, item, callback) ->
    db = new MongoDb config
    async.waterfall [
      (ck) ->
        db.open table, ck
      (coll, ck) ->
        db.collection.update {_id : id}, {$set : item}, {multi : false, safe : true, upsert : false}, ck
    ], (err) ->
      db.close()
      callback err

exports.MongoDb = MongoDb