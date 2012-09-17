sinon = require('./test_helper').sinon
Builder = require '../src/builder'


describe 'Builder', ->

    it 'returns an empty string for new Builders', ->
      new Builder().result().should.equal ''

    it 'returns the given data', ->
      new Builder().append('one ').append('two').result().should.equal 'one two'


