// Generated by CoffeeScript 1.6.2
(function() {
  var async, close, connection, get, getById, getConfig, getSingle, insert, mongodb, open, remove, removeById, setConfig, updateById, _, _config, _mapItems, _muteParams2, _muteParams3,
    _this = this;

  connection = require("./connection");

  mongodb = require("mongodb");

  _ = require("underscore");

  async = require("async");

  _config = null;

  setConfig = function(config) {
    return _config = config;
  };

  insert = function(table, item, autoMap, done) {
    var params;

    params = _muteParams2(autoMap, done);
    return async.waterfall([
      function(ck) {
        return open(table, ck);
      }, function(coll, ck) {
        var ins;

        if (params.opts) {
          ins = _.extend({}, item);
          ins._id = item.id;
          delete ins.id;
        }
        return coll.insert(item, {
          safe: true
        }, function(err, doc) {
          close(coll);
          return ck(err, doc);
        });
      }
    ], function(err, res) {
      if (!err && res) {
        _.extend(true, item, res);
        _mapItems(err, params.opts, item);
      }
      return params.callback(err, item);
    });
  };

  get = function(table, filter, select, autoMap, done) {
    var params;

    params = _muteParams3(select, autoMap, done);
    return async.waterfall([
      function(ck) {
        return open(table, ck);
      }, function(coll, ck) {
        return coll.find(filter, params.obj).toArray(function(err, items) {
          close(coll);
          return ck(err, items);
        });
      }
    ], function(err, items) {
      _mapItems(err, params.opts, items);
      return params.callback(err, items);
    });
  };

  getSingle = function(table, filter, select, autoMap, done) {
    var params;

    params = _muteParams3(select, autoMap, done);
    return get(table, filter, params.obj, params.opts, function(err, items) {
      return params.callback(err, err ? null : items[0]);
    });
  };

  getById = function(table, id, select, autoMap, done) {
    var params;

    params = _muteParams3(select, autoMap, done);
    return getSingle(table, {
      _id: new mongodb.ObjectID(id)
    }, params.obj, params.opts, params.callback);
  };

  remove = function(table, filter, done) {
    return async.waterfall([
      function(ck) {
        return open(table, ck);
      }, function(coll, ck) {
        return coll.remove(filter, function(err) {
          close(coll);
          return ck(err);
        });
      }
    ], done);
  };

  removeById = function(table, id, done) {
    return remove(table, {
      _id: new mongodb.ObjectID(id)
    }, done);
  };

  updateById = function(table, id, item, isJustFields, done) {
    var params;

    params = _muteParams2(isJustFields, done);
    return async.waterfall([
      function(ck) {
        return open(table, ck);
      }, function(coll, ck) {
        var updItem;

        updItem = _.extend({}, item);
        if (params.opts) {
          delete updItem.id;
          delete updItem._id;
        }
        return coll.update({
          _id: new mongodb.ObjectID(id)
        }, (params.opts ? {
          $set: updItem
        } : item), {
          multi: false,
          safe: true,
          upsert: false
        }, function(err) {
          close(coll);
          return ck(err);
        });
      }
    ], params.callback);
  };

  _mapItems = function(err, autoMap, items) {
    var item, _i, _len, _results;

    if (!err && autoMap) {
      if (!_.isArray(items)) {
        items = [items];
      }
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        item.id = item._id.toHexString();
        _results.push(delete item._id);
      }
      return _results;
    }
  };

  _muteParams2 = function(opts, callback) {
    var params;

    params = {};
    if (_.isFunction(opts)) {
      params.callback = opts;
      params.opts = true;
    } else {
      params.callback = callback;
      params.opts = opts === false ? false : true;
    }
    return params;
  };

  _muteParams3 = function(obj, opts, callback) {
    var params;

    params = {};
    if (_.isFunction(obj)) {
      params.callback = obj;
      params.obj = {};
      params.opts = true;
    } else if (_.isFunction(opts)) {
      if (_.isBoolean(obj)) {
        params.callback = opts;
        params.obj = {};
        params.opts = obj;
      } else {
        params.callback = opts;
        params.obj = obj ? obj : {};
        params.opts = true;
      }
    } else {
      params.callback = callback;
      params.obj = obj ? obj : {};
      params.opts = opts;
    }
    return params;
  };

  getConfig = function() {
    if (_config && _config.uri) {
      return connection.str2config(_config.uri);
    } else {
      return _config;
    }
  };

  open = function(table, done) {
    var config, db,
      _this = this;

    config = getConfig();
    if (!config) {
      done(new Error("config not initialized"));
      return;
    }
    db = new mongodb.Db(config.database, new mongodb.Server(config.host, config.port), {
      w: 1
    });
    return async.waterfall([
      function(ck) {
        return db.open(ck);
      }, function(d, ck) {
        if (config.user) {
          return db.authenticate(config.user, config.pass, ck);
        } else {
          return ck(null, null);
        }
      }, function(f, ck) {
        return db.collection(table, ck);
      }
    ], done);
  };

  close = function(coll) {
    if (coll) {
      return coll.db.close();
    }
  };

  exports.setConfig = setConfig;

  exports.insert = insert;

  exports.get = get;

  exports.getSingle = getSingle;

  exports.getById = getById;

  exports.remove = remove;

  exports.removeById = removeById;

  exports.updateById = updateById;

  exports.open = open;

  exports.close = close;

}).call(this);

/*
//@ sourceMappingURL=mongo.map
*/
