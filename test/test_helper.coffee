chai = require 'chai'
module.exports = [chai.expect, require('sinon'), chai]
chai.use require('sinon-chai')
