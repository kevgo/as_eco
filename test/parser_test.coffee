[expect, sinon, chai] = require './test_helper'


Parser = require '../src/parser'

chai.Assertion.overwriteMethod 'eql', (_super) ->
  (value) ->
    try
      _super.call this, value
    catch error
      console.log '*Expected*'
      console.log value
      console.log '*Actual*'
      console.log @_obj
      throw error


chai.Assertion.addMethod 'equal_string', (expected) ->
  actual = @_obj
  if actual != expected
    throw { expected: expected, actual: actual }


describe 'Parser', ->

  describe 'parse', ->

    it 'parses the given AsEco text', ->
      result = Parser.parse 'one <% two %> three'
      expect(result).to.have.length 3
      expect(result[0]).to.eql type: 'text', data: 'one '
      expect(result[1]).to.eql type: 'exp', data: 'two'
      expect(result[2]).to.eql type: 'text', data: ' three'


  describe 'recognize_segments', ->

    it 'leaves TEXT segments alone', ->
      result = Parser.recognize_segments [ type: 'text', data: 'foo' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'text', data: 'foo'

    it 'recognizes expressions', ->
      result = Parser.recognize_segments [ type: 'js', data: ' a=1 ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'exp', data: 'a=1'

    it 'recognizes output', ->
      result = Parser.recognize_segments [ type: 'js', data: '= 1+1 ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'out', data: '1+1'

    it 'recognizes indenting clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: 'if a:' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'exp', data: 'if a:'

    it 'recognizes else clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' else: ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'else', data: ''

    it 'recognizes end clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' end ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'end', data: ''

    it 'recognizes for clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' for user in users: ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'for', data: 'user in users:'

    it 'recognizes for clauses with special characters', ->
      result = Parser.recognize_segments [ type: 'js', data: ' for i in [1,2]: ' ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'for', data: 'i in [1,2]:'

    it 'recognizes ASYNC expressions', ->
      result = Parser.recognize_segments [ type: 'js', data: "async user, 'get', 'result' " ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'async', data: "user, 'get', 'result'"

    it 'recognizes ASYNC expressions with leading space', ->
      result = Parser.recognize_segments [ type: 'js', data: " async user, 'get', 'result' " ]
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'async', data: "user, 'get', 'result'"


  describe 'segment', ->

    it 'returns arrays', ->
      result = Parser.segment ''
      expect(result).to.to.be.instanceof Array

    it 'returns static text as a TEXT segment', ->
      result = Parser.segment 'foo'
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'text', data: 'foo'

    it 'returns expressions as a JS segment', ->
      result = Parser.segment '<% a=1 %>'
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'js', data: ' a=1 '

    it 'returns JS output as a JS segment', ->
      result = Parser.segment '<%= 1+1 %>'
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'js', data: '= 1+1 '

    it 'returns an asynchronous JS expression as a JS segment', ->
      result = Parser.segment "<%async user.get, result %>"
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'js', data: "async user.get, result "

    it 'allows to have spaces before the async keyword', ->
      result = Parser.segment "<% async user.get, result %>"
      expect(result).to.have.length 1
      expect(result[0]).to.eql type: 'js', data: " async user.get, result "

    it 'can handle lots of different segments in a text', ->
      result = Parser.segment 'one <% two %> three <% four %> five'
      expect(result).to.have.length 5
      expect(result[0]).to.eql type: 'text', data: 'one '
      expect(result[1]).to.eql type: 'js', data: ' two '
      expect(result[2]).to.eql type: 'text', data: ' three '
      expect(result[3]).to.eql type: 'js', data: ' four '
      expect(result[4]).to.eql type: 'text', data: ' five'

