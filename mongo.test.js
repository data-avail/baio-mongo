// Generated by CoffeeScript 1.3.3
(function() {
  var config, mongo, should;

  mongo = require("./mongo");

  should = require("should");

  config = {
    uri: "mongodb://adm:123@ds051067.mongolab.com:51067/stage"
  };

  describe("mongo basic operations without config", function() {
    return describe("insert item", function() {
      return it("should be error 'config not initialized'", function(done) {
        var item;
        item = {
          name: 'baio',
          pass: 'xxx'
        };
        return mongo.insert("test", item, function(err) {
          err.message.should.equal("config not initialized");
          return done();
        });
      });
    });
  });

  describe("mongo basic operations", function() {
    before(function(done) {
      mongo.setConfig(config);
      return mongo.remove("test", {
        name: "baio"
      }, done);
    });
    it("insert item should be ok, item.id should be returned", function(done) {
      var item;
      item = {
        name: 'baio',
        pass: 'xxx'
      };
      return mongo.insert("test", item, function(err, res) {
        should.not.exist(err);
        item.should.equal(res);
        item.should.have.keys("name", "pass", "id");
        return done();
      });
    });
    it("insert item, but no map, should be ok, item.id should be returned", function(done) {
      var item;
      item = {
        name: 'baio',
        pass: 'xxx'
      };
      return mongo.insert("test", item, false, function(err, res) {
        should.not.exist(err);
        item.should.equal(res);
        item.should.have.keys("_id", "name", "pass");
        return done();
      });
    });
    it("get by name, should return 2 items", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, {}, false, function(err, res) {
        var i, _i, _len;
        should.not.exist(err);
        res.should.have.length(2);
        for (_i = 0, _len = res.length; _i < _len; _i++) {
          i = res[_i];
          i.should.have.keys("_id", "name", "pass");
          i.name.should.equal("baio");
          i.pass.should.equal("xxx");
        }
        return done();
      });
    });
    it("getSingle / updateById / getById / updateById, should be ok", function(done) {
      return mongo.getSingle("test", {
        name: "baio"
      }, {}, false, function(err, res) {
        should.not.exist(err);
        res.should.have.keys("_id", "name", "pass");
        res.name.should.equal("baio");
        res.pass.should.equal("xxx");
        return mongo.updateById("test", res._id.toHexString(), {
          new_field: true
        }, true, function(err) {
          should.not.exist(err);
          return mongo.getById("test", res._id.toHexString(), {
            pass: 1,
            new_field: 1
          }, false, function(err, res) {
            should.not.exist(err);
            res.should.have.keys("_id", "pass", "new_field");
            res.pass.should.equal("xxx");
            res.new_field.should.equal(true);
            return mongo.updateById("test", res._id.toHexString(), {
              $unset: {
                new_field: 1
              }
            }, false, function(err) {
              should.not.exist(err);
              return done();
            });
          });
        });
      });
    });
    it("get with mapping", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, {}, true, function(err, res) {
        var i, _i, _len;
        should.not.exist(err);
        res.should.have.length(2);
        for (_i = 0, _len = res.length; _i < _len; _i++) {
          i = res[_i];
          i.should.have.keys("id", "name", "pass");
          i.name.should.equal("baio");
          i.pass.should.equal("xxx");
        }
        return mongo.getSingle("test", {
          name: "baio"
        }, {}, true, function(err, res) {
          should.not.exist(err);
          res.should.have.keys("id", "name", "pass");
          return mongo.getById("test", res.id, {
            pass: 1
          }, true, function(err, res) {
            should.not.exist(err);
            res.should.have.keys("id", "pass");
            res.pass.should.equal("xxx");
            return done();
          });
        });
      });
    });
    it("delete by name should be ok", function(done) {
      return mongo.remove("test", {
        name: "baio"
      }, done);
    });
    return it("get by name now we should get 0 items", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, {}, function(err, res) {
        should.not.exist(err);
        res.should.have.length(0);
        return done();
      });
    });
  });

  describe("mongo operations with default aparametrs", function() {
    before(function(done) {
      mongo.setConfig(config);
      return mongo.remove("test", {
        name: "baio"
      }, done);
    });
    it("insert @automMap missed, should autoMap id parameter", function(done) {
      var item;
      item = {
        name: 'baio',
        pass: 'xxx'
      };
      return mongo.insert("test", item, function(err, res) {
        should.not.exist(err);
        item.should.equal(res);
        item.should.have.keys("id", "name", "pass");
        return done();
      });
    });
    it("insert @automMap = true, should autoMap id parameter", function(done) {
      var item;
      item = {
        name: 'baio',
        pass: 'xxx'
      };
      return mongo.insert("test", item, true, function(err, res) {
        should.not.exist(err);
        item.should.equal(res);
        item.should.have.keys("id", "name", "pass");
        return done();
      });
    });
    it("insert @automMap = false, should NOT autoMap id parameter", function(done) {
      var item;
      item = {
        name: 'baio',
        pass: 'xxx'
      };
      return mongo.insert("test", item, false, function(err, res) {
        should.not.exist(err);
        item.should.equal(res);
        item.should.have.keys("_id", "name", "pass");
        return done();
      });
    });
    it("get @select - missed, @autoMap missed - should select all and autoMap id", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, function(err, res) {
        var i, _i, _len;
        should.not.exist(err);
        res.should.have.length(3);
        for (_i = 0, _len = res.length; _i < _len; _i++) {
          i = res[_i];
          i.should.have.keys("id", "name", "pass");
          i.name.should.equal("baio");
          i.pass.should.equal("xxx");
        }
        return done();
      });
    });
    it("get @select - missed, @autoMap = false - should select all and NOT autoMap id", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, false, function(err, res) {
        var i, _i, _len;
        should.not.exist(err);
        res.should.have.length(3);
        for (_i = 0, _len = res.length; _i < _len; _i++) {
          i = res[_i];
          i.should.have.keys("_id", "name", "pass");
          i.name.should.equal("baio");
          i.pass.should.equal("xxx");
        }
        return done();
      });
    });
    it("get @select - {password : 1}, @autoMap = missed - should select password, NOT name and autoMap id", function(done) {
      return mongo.get("test", {
        name: "baio"
      }, {
        pass: 1
      }, function(err, res) {
        var i, _i, _len;
        should.not.exist(err);
        res.should.have.length(3);
        for (_i = 0, _len = res.length; _i < _len; _i++) {
          i = res[_i];
          i.should.have.keys("id", "pass");
          i.pass.should.equal("xxx");
        }
        return done();
      });
    });
    it("get / updateById with missed isJustFields parameter", function(done) {
      return mongo.getSingle("test", {
        name: "baio"
      }, {
        pass: 1
      }, function(err, res) {
        should.not.exist(err);
        return mongo.updateById("test", res.id, {
          new_field: 2
        }, done);
      });
    });
    return it("delete by name should be ok", function(done) {
      return mongo.remove("test", {
        name: "baio"
      }, done);
    });
  });

}).call(this);
