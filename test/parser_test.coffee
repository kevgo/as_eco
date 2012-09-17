test_helper = require('./test_helper')
sinon = test_helper.sinon
chai = test_helper.chai

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
      result.should.have.length 3
      result[0].should.eql type: 'text', data: 'one '
      result[1].should.eql type: 'exp', data: 'two'
      result[2].should.eql type: 'text', data: ' three'


  describe 'recognize_segments', ->

    it 'leaves TEXT segments alone', ->
      result = Parser.recognize_segments [ type: 'text', data: 'foo' ]
      result.should.have.length 1
      result[0].should.eql type: 'text', data: 'foo'

    it 'recognizes expressions', ->
      result = Parser.recognize_segments [ type: 'js', data: ' a=1 ' ]
      result.should.have.length 1
      result[0].should.eql type: 'exp', data: 'a=1'

    it 'recognizes output', ->
      result = Parser.recognize_segments [ type: 'js', data: '= 1+1 ' ]
      result.should.have.length 1
      result[0].should.eql type: 'out', data: '1+1'

    it 'recognizes indenting clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: 'if a:' ]
      result.should.have.length 1
      result[0].should.eql type: 'exp', data: 'if a:'

    it 'recognizes else clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' else: ' ]
      result.should.have.length 1
      result[0].should.eql type: 'else', data: ''

    it 'recognizes end clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' end ' ]
      result.should.have.length 1
      result[0].should.eql type: 'end', data: ''

    it 'recognizes for clauses', ->
      result = Parser.recognize_segments [ type: 'js', data: ' for user in users: ' ]
      result.should.have.length 1
      result[0].should.eql type: 'for', data: 'user in users:'

    it 'recognizes for clauses with special characters', ->
      result = Parser.recognize_segments [ type: 'js', data: ' for i in [1,2]: ' ]
      result.should.have.length 1
      result[0].should.eql type: 'for', data: 'i in [1,2]:'

    it 'recognizes ASYNC expressions', ->
      result = Parser.recognize_segments [ type: 'js', data: "async user, 'get', 'result' " ]
      result.should.have.length 1
      result[0].should.eql type: 'async', data: "user, 'get', 'result'"

    it 'recognizes ASYNC expressions with leading space', ->
      result = Parser.recognize_segments [ type: 'js', data: " async user, 'get', 'result' " ]
      result.should.have.length 1
      result[0].should.eql type: 'async', data: "user, 'get', 'result'"


  describe 'segment', ->

    it 'returns arrays', ->
      result = Parser.segment ''
      result.should.to.be.instanceof Array

    it 'returns static text as a TEXT segment', ->
      result = Parser.segment 'foo'
      result.should.have.length 1
      result[0].should.eql type: 'text', data: 'foo'

    it 'returns expressions as a JS segment', ->
      result = Parser.segment '<% a=1 %>'
      result.should.have.length 1
      result[0].should.eql type: 'js', data: ' a=1 '

    it 'returns JS output as a JS segment', ->
      result = Parser.segment '<%= 1+1 %>'
      result.should.have.length 1
      result[0].should.eql type: 'js', data: '= 1+1 '

    it 'returns an asynchronous JS expression as a JS segment', ->
      result = Parser.segment "<%async user.get, result %>"
      result.should.have.length 1
      result[0].should.eql type: 'js', data: "async user.get, result "

    it 'allows to have spaces before the async keyword', ->
      result = Parser.segment "<% async user.get, result %>"
      result.should.have.length 1
      result[0].should.eql type: 'js', data: " async user.get, result "

    it 'can handle lots of different segments in a text', ->
      result = Parser.segment 'one <% two %> three <% four %> five'
      result.should.have.length 5
      result[0].should.eql type: 'text', data: 'one '
      result[1].should.eql type: 'js', data: ' two '
      result[2].should.eql type: 'text', data: ' three '
      result[3].should.eql type: 'js', data: ' four '
      result[4].should.eql type: 'text', data: ' five'

