mongo = require "./mongo"
should = require "should"

config =
    uri : "mongodb://adm:123@ds051067.mongolab.com:51067/stage"

describe "mongo basic operations without config", ->

  describe "insert item", ->
    it "should be error 'config not initialized'", (done)->
      item = name : 'baio', pass : 'xxx'
      mongo.insert "test", item, (err) ->
        err.message.should.equal "config not initialized"
        done()

describe "mongo basic operations", ->

  before (done) ->
    mongo.setConfig config
    mongo.remove "test", {name : "baio"}, done

  it "insert item should be ok, item.id should be returned", (done)->
    item = name : 'baio', pass : 'xxx'
    mongo.insert "test", item, (err, res) ->
      should.not.exist err
      item.should.equal res
      item.should.have.keys "name", "pass", "id"
      done()

  it "insert item, but no map, should be ok, item.id should be returned", (done)->
    item = name : 'baio', pass : 'xxx'
    mongo.insert "test", item, false, (err, res) ->
      should.not.exist err
      item.should.equal res
      item.should.have.keys "_id", "name", "pass"
      done()

  it "get by name, should return 2 items", (done)->
    mongo.get "test", {name : "baio"}, {}, false, (err, res) ->
      should.not.exist err
      res.should.have.length 2
      for i in res
        i.should.have.keys "_id", "name", "pass"
        i.name.should.equal "baio"
        i.pass.should.equal "xxx"
      done()

  it "getSingle / updateById / getById / updateById, should be ok", (done)->
    mongo.getSingle "test", {name : "baio"}, {}, false, (err, res) ->
      should.not.exist err
      res.should.have.keys "_id", "name", "pass"
      res.name.should.equal "baio"
      res.pass.should.equal "xxx"
      mongo.updateById "test", res._id.toHexString(), {new_field : true}, true, (err) ->
        should.not.exist err
        mongo.getById "test", res._id.toHexString(), {pass : 1, new_field : 1}, false, (err, res) ->
          should.not.exist err
          res.should.have.keys "_id", "pass", "new_field"
          res.pass.should.equal "xxx"
          res.new_field.should.equal true
          mongo.updateById "test", res._id.toHexString(), {$unset : {new_field : 1}}, false, (err) ->
            should.not.exist err
            done()

        #unset new_field here

  it "get with mapping", (done)->
    mongo.get "test", {name : "baio"}, {}, true, (err, res) ->
      should.not.exist err
      res.should.have.length 2
      for i in res
        i.should.have.keys "id", "name", "pass"
        i.name.should.equal "baio"
        i.pass.should.equal "xxx"
      mongo.getSingle "test", {name : "baio"}, {}, true, (err, res) ->
        should.not.exist err
        res.should.have.keys "id", "name", "pass"
        mongo.getById "test", res.id, {pass : 1}, true, (err, res) ->
          should.not.exist err
          res.should.have.keys "id", "pass"
          res.pass.should.equal "xxx"
          done()

  it "delete by name should be ok", (done)->
    mongo.remove "test", {name : "baio"}, done

  it "get by name now we should get 0 items", (done)->
    mongo.get "test", {name : "baio"}, {}, (err, res) ->
      should.not.exist err
      res.should.have.length 0
      done()

describe "mongo operations with default aparametrs", ->

  before (done) ->
    mongo.setConfig config
    mongo.remove "test", {name : "baio"}, done

  it "insert @automMap missed, should autoMap id parameter", (done)->
    item = name : 'baio', pass : 'xxx'
    mongo.insert "test", item, (err, res) ->
      should.not.exist err
      item.should.equal res
      item.should.have.keys "id", "name", "pass"
      done()

  it "insert @automMap = true, should autoMap id parameter", (done)->
    item = name : 'baio', pass : 'xxx'
    mongo.insert "test", item, true, (err, res) ->
      should.not.exist err
      item.should.equal res
      item.should.have.keys "id", "name", "pass"
      done()

  it "insert @automMap = false, should NOT autoMap id parameter", (done)->
    item = name : 'baio', pass : 'xxx'
    mongo.insert "test", item, false, (err, res) ->
      should.not.exist err
      item.should.equal res
      item.should.have.keys "_id", "name", "pass"
      done()

  it "get @select - missed, @autoMap missed - should select all and autoMap id", (done)->
    mongo.get "test", {name : "baio"}, (err, res) ->
      should.not.exist err
      res.should.have.length 3
      for i in res
        i.should.have.keys "id", "name", "pass"
        i.name.should.equal "baio"
        i.pass.should.equal "xxx"
      done()

  it "get @select - missed, @autoMap = false - should select all and NOT autoMap id", (done)->
    mongo.get "test", {name : "baio"}, false, (err, res) ->
      should.not.exist err
      res.should.have.length 3
      for i in res
        i.should.have.keys "_id", "name", "pass"
        i.name.should.equal "baio"
        i.pass.should.equal "xxx"
      done()

  it "get @select - {password : 1}, @autoMap = missed - should select password, NOT name and autoMap id", (done)->
    mongo.get "test", {name : "baio"}, {pass : 1}, (err, res) ->
      should.not.exist err
      res.should.have.length 3
      for i in res
        i.should.have.keys "id", "pass"
        i.pass.should.equal "xxx"
      done()

  it "get / updateById with missed isJustFields parameter", (done)->
    mongo.getSingle "test", {name : "baio"}, {pass : 1}, (err, res) ->
      should.not.exist err
      mongo.updateById "test", res.id, {new_field : 2}, done

  it "delete by name should be ok", (done)->
    mongo.remove "test", {name : "baio"}, done
