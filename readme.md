baio-mongo
----------

[![Build Status](https://travis-ci.org/data-avail/baio-mongo.png)](https://travis-ci.org/data-avail/baio-mongo.png)

2013 Max Putilov, Data-Avail

Baio-mongo may be freely distributed under the MIT license.

The set of atomic operations to deal with native mongodb driver.

It is often for server side applications, when your need single db operation per request/response cycle, this library
facilitate this.

Open connection -> Single CRUD operation -> Close connection.

[Documentation](http://data-avail.github.com/baio-mongo/mongo.html)

###Install###
npm install baio-mongo

###Tests###
npm test
