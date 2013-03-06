[expect, sinon, chai] = require './test_helper'


IndentationCounter = require '../src/indentation_counter'


describe 'IndentationCounter', ->


  indentation_counter = null
  beforeEach ->
    indentation_counter = new IndentationCounter


  describe 'constructor', ->

    it 'initializes with 0 indentation', ->
      expect(indentation_counter.indentation_level()).to.equal 0


  describe 'indent', ->

    it 'increases the indentation by the given amount', ->
      indentation_counter.indent 2
      expect(indentation_counter.indentation_level()).to.equal 2

    it 'defaults to an increase of 1 units', ->
      indentation_counter.indent()
      expect(indentation_counter.indentation_level()).to.equal 1

    it 'accumulates the indentation', ->
      indentation_counter.indent 2
      indentation_counter.indent 4
      expect(indentation_counter.indentation_level()).to.equal 6


  describe 'undent', ->

    it 'removes the indentation by the last given step', ->
      indentation_counter.indent 2
      indentation_counter.indent 4
      expect(indentation_counter.indentation_level()).to.equal 6
      indentation_counter.undent()
      expect(indentation_counter.indentation_level()).to.equal 2


    it 'throws an exception if there is nothing to undent', ->
      try
        indentation_counter.undent()
        throw 'Expected an exception to be thrown here.'
      catch error
        throw error if error != 'Error: Nothing to undent.'
