sinon = require('./test_helper').sinon
as_eco = require '../src/as_eco'


describe 'as_eco', ->

  beforeEach ->
    as_eco.reset()


  describe 'compile', ->
    it 'converts the template into a function and stores it in @render_functions', ->
      as_eco.compile 'foo', 'bar'
      as_eco.render_functions.should.have.property 'foo'


  describe 'logging', ->
    beforeEach -> sinon.stub console, 'log'
    afterEach -> console.log.restore()

    describe 'default behavior', ->
      it 'does not log', ->
        as_eco.logging.should.be.false

    describe 'when activated', ->
      it 'logs the compiled function on the console', ->
        as_eco.logging = true
        as_eco.compile 'foo', 'bar'
        console.log.should.have.been.called

    describe 'when deactivated', ->
      it 'does not log the compiled function on the console', ->
        as_eco.logging = false
        as_eco.compile 'foo', 'bar'
        console.log.should.not.have.been.called


  describe 'compile_file', ->

    it 'compiles the given file', (done) ->
      as_eco.compile_file './test/aseco_test.as_eco', ->
        as_eco.render_functions.should.have.property './test/aseco_test.as_eco'
        done()


  describe 'has_compiled_template', ->

    it 'returns true if the given template is already compiled', ->
      as_eco.render_functions['foo'] = 'bar'
      as_eco.has_compiled_template('foo').should.be.true

    it 'returns false if the given template is not compiled yet', ->
      as_eco.has_compiled_template('foo').should.be.false


  describe 'escape', ->

    it 'escapes html tags', ->
      as_eco.escape('<script>').should.equal '&lt;script&gt;'

    it 'escapes ampersands', ->
      as_eco.escape('foo & bar').should.equal 'foo &amp; bar'

    it 'escapes double-quotes', ->
      as_eco.escape('"').should.equal '&quot;'

    it 'converts non-string parameters to string first', ->
      as_eco.escape(5).should.equal '5'


  describe 'render', ->

    result = null
    outstream = (text) -> result += text
    beforeEach ->
      result = ''
    
    it 'renders static text through the given output stream', (done) ->
      as_eco.compile 'foo', 'text'
      as_eco.render 'foo', null, outstream, ->
        result.should.eql 'text'
        done()

    it 'renders javascript into the output stream', (done) ->
      as_eco.compile 'foo', '<% a = 5 %><%= a %>'
      as_eco.render 'foo', null, outstream, ->
        result.should.eql '5'
        done()

    it 'renders data into the template', (done) ->
      as_eco.compile 'foo', '<%= @a %>'
      as_eco.render 'foo', { a: 5 }, outstream, ->
        result.should.eql '5'
        done()

    it 'HTML-escapes data inserted into the template', (done) ->
      as_eco.compile 'foo', '<%= @a %>'
      as_eco.render 'foo', { a: '<script>' }, outstream, ->
        result.should.eql '&lt;script&gt;'
        done()


    describe 'asynchronous CS', ->

      it 'works on a single level', ->
        as_eco.compile 'foo', '<%async @user_future.get, user %><%= user %>'
        as_eco.render 'foo', { user_future: { get: -> 5 }}, outstream, ->
          result.should.eql '5'
          done()

      it 'works on multiple levels', ->
        as_eco.compile 'foo', '<%async @user_future.get, user %><%async @city_future.get, city %><%= city %>'
        user_future = { get: -> 5 }
        city_future = { get: -> 6 }
        as_eco.render 'foo', { user_future: user_future, city_future: city_future }, outstream, ->
          result.should.eql '6'
          done()


    describe 'if clauses', ->

      it 'renders the happy path if the clause is truthy', (done) ->
        template = """<% if @a: %>
                        yes!
                      <% end %>"""
        as_eco.compile 'foo', template
        as_eco.render 'foo', { a: true }, outstream, ->
          result.trim().should.equal 'yes!'
          done()

      it 'renders the unhappy path if the clause is falsy', (done) ->
        as_eco.compile 'foo', """<% if @a: %>
                                   yes!
                                 <% else: %>
                                   no!
                                 <% end %>"""
        as_eco.render 'foo', { a: false }, outstream, ->
          result.trim().should.equal 'no!'
          done()


    describe 'for-loops', ->

      it 'renders for-loops', (done) ->
        as_eco.compile 'foo', """<% for i in [1,2]: %>
                                   i: <%= i %>
                                 <% end %>"""
        as_eco.render 'foo', {}, outstream, ->
          result.should.match /i: 1\s*i: 2/
          done()


  describe 'render_file', ->

    describe 'when the template is already compiled', ->

      it 'does not compile the template again', (done) ->
        sinon.spy as_eco, 'compile_file'
        as_eco.render_functions['foo'] = ->
          as_eco.compile_file.should.not.have.been.called
          as_eco.compile_file.restore()
          done()
        as_eco.render_file 'foo', {}, 'out', 'done'

      it 'renders the template', (done) ->
        as_eco.render_functions['foo'] = (out, done_cb) ->
          this.should.eql {data: 1}
          out.should.equal 'out'
          done_cb.should.equal 'done'
          done()
        as_eco.render_file 'foo', {data: 1}, 'out', 'done'

    describe 'when the template is not compiled yet', ->

      it 'compiles the template', (done) ->
        out = ->
        as_eco.render_file './test/aseco_test.as_eco', {}, out, ->
          as_eco.render_functions.should.have.property './test/aseco_test.as_eco'
          done()

      it 'renders the template', (done) ->
        sinon.spy as_eco, 'render'
        out = sinon.spy()
        as_eco.render_file './test/aseco_test.as_eco', {}, out, ->
          out.should.have.been.called
          done()


  describe 'reset', ->
    it 'removes all compiled render functions', ->
      as_eco.render_functions['foo'] = 'bar'
      as_eco.reset()
      as_eco.render_functions.should.eql {}


  describe 'with_logging', ->

    it 'runs the given function', ->
      called = false
      as_eco.with_logging ->
        called = true
      called.should.be.true


    it 'runs the given function with logging enabled', ->
      as_eco.logging = false
      as_eco.with_logging ->
        as_eco.logging.should.be.true


    it 'restores the logging to false if it was false before', ->
      as_eco.logging = false
      as_eco.with_logging ->
      as_eco.logging.should.be.false

    it 'leaves the logging enabled if it was enabled before', ->
      as_eco.logging = true
      as_eco.with_logging ->
      as_eco.logging.should.be.true
