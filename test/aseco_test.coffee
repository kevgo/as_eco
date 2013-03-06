[expect, sinon, chai] = require './test_helper'
as_eco = require '../src/as_eco'


describe 'as_eco', ->

  beforeEach ->
    as_eco.reset()


  describe 'compile', ->
    it 'converts the template into a function and stores it in @render_functions', ->
      as_eco.compile 'foo', 'bar'
      expect(as_eco.render_functions).to.have.property 'foo'


  describe 'logging', ->
    beforeEach -> sinon.stub console, 'log'
    afterEach -> console.log.restore()

    describe 'default behavior', ->
      it 'does not log', ->
        expect(as_eco.logging).to.be.false

    describe 'when activated', ->
      it 'logs the compiled function on the console', ->
        as_eco.logging = true
        as_eco.compile 'foo', 'bar'
        expect(console.log).to.have.been.called

    describe 'when deactivated', ->
      it 'does not log the compiled function on the console', ->
        as_eco.logging = false
        as_eco.compile 'foo', 'bar'
        expect(console.log).to.not.have.been.called


  describe 'compile_file', ->

    it 'compiles the given file', (done) ->
      as_eco.compile_file './test/aseco_test.as_eco', ->
        expect(as_eco.render_functions).to.have.property './test/aseco_test.as_eco'
        done()


  describe 'has_compiled_template', ->

    it 'returns true if the given template is already compiled', ->
      as_eco.render_functions['foo'] = 'bar'
      expect(as_eco.has_compiled_template('foo')).to.be.true

    it 'returns false if the given template is not compiled yet', ->
      expect(as_eco.has_compiled_template('foo')).to.be.false


  describe 'escape', ->

    it 'escapes html tags', ->
      expect(as_eco.escape('<script>')).to.equal '&lt;script&gt;'

    it 'escapes ampersands', ->
      expect(as_eco.escape('foo & bar')).to.equal 'foo &amp; bar'

    it 'escapes double-quotes', ->
      expect(as_eco.escape('"')).to.equal '&quot;'

    it 'converts non-string parameters to string first', ->
      expect(as_eco.escape(5)).to.equal '5'


  describe 'render', ->

    result = null
    outstream = (text) -> result += text
    beforeEach ->
      result = ''

    it 'renders static text through the given output stream', (done) ->
      as_eco.compile 'foo', 'text'
      as_eco.render 'foo', null, outstream, ->
        expect(result).to.eql 'text'
        done()

    it 'renders javascript into the output stream', (done) ->
      as_eco.compile 'foo', '<% a = 5 %><%= a %>'
      as_eco.render 'foo', null, outstream, ->
        expect(result).to.eql '5'
        done()

    it 'renders data into the template', (done) ->
      as_eco.compile 'foo', '<%= @a %>'
      as_eco.render 'foo', { a: 5 }, outstream, ->
        expect(result).to.eql '5'
        done()

    it 'HTML-escapes data inserted into the template', (done) ->
      as_eco.compile 'foo', '<%= @a %>'
      as_eco.render 'foo', { a: '<script>' }, outstream, ->
        expect(result).to.eql '&lt;script&gt;'
        done()


    describe 'asynchronous CS', ->

      it 'works on a single level', ->
        as_eco.compile 'foo', '<%async @user_future.get, user %><%= user %>'
        as_eco.render 'foo', { user_future: { get: -> 5 }}, outstream, ->
          expect(result).to.eql '5'
          done()

      it 'works on multiple levels', ->
        as_eco.compile 'foo', '<%async @user_future.get, user %><%async @city_future.get, city %><%= city %>'
        user_future = { get: -> 5 }
        city_future = { get: -> 6 }
        as_eco.render 'foo', { user_future: user_future, city_future: city_future }, outstream, ->
          expect(result).to.eql '6'
          done()


    describe 'if clauses', ->

      it 'renders the happy path if the clause is truthy', (done) ->
        template = """<% if @a: %>
                        yes!
                      <% end %>"""
        as_eco.compile 'foo', template
        as_eco.render 'foo', { a: true }, outstream, ->
          expect(result.trim()).to.equal 'yes!'
          done()

      it 'renders the unhappy path if the clause is falsy', (done) ->
        as_eco.compile 'foo', """<% if @a: %>
                                   yes!
                                 <% else: %>
                                   no!
                                 <% end %>"""
        as_eco.render 'foo', { a: false }, outstream, ->
          expect(result.trim()).to.equal 'no!'
          done()


    describe 'for-loops', ->

      it 'renders for-loops', (done) ->
        as_eco.compile 'foo', """<% for i in [1,2]: %>
                                   i: <%= i %>
                                 <% end %>"""
        as_eco.render 'foo', {}, outstream, ->
          expect(result).to.match /i: 1\s*i: 2/
          done()


  describe 'render_file', ->

    describe 'when the template is already compiled', ->

      it 'does not compile the template again', (done) ->
        sinon.spy as_eco, 'compile_file'
        as_eco.render_functions['foo'] = ->
          expect(as_eco.compile_file).to.not.have.been.called
          as_eco.compile_file.restore()
          done()
        as_eco.render_file 'foo', {}, 'out', 'done'

      it 'renders the template', (done) ->
        as_eco.render_functions['foo'] = (out, done_cb) ->
          expect(this).to.eql {data: 1}
          expect(out).to.equal 'out'
          expect(done_cb).to.equal 'done'
          done()
        as_eco.render_file 'foo', {data: 1}, 'out', 'done'

    describe 'when the template is not compiled yet', ->

      it 'compiles the template', (done) ->
        out = ->
        as_eco.render_file './test/aseco_test.as_eco', {}, out, ->
          expect(as_eco.render_functions).to.have.property './test/aseco_test.as_eco'
          done()

      it 'renders the template', (done) ->
        sinon.spy as_eco, 'render'
        out = sinon.spy()
        as_eco.render_file './test/aseco_test.as_eco', {}, out, ->
          expect(out).to.have.been.called
          done()


  describe 'reset', ->
    it 'removes all compiled render functions', ->
      as_eco.render_functions['foo'] = 'bar'
      as_eco.reset()
      expect(as_eco.render_functions).to.eql {}


  describe 'with_logging', ->

    it 'runs the given function', ->
      called = false
      as_eco.with_logging ->
        called = true
      expect(called).to.be.true


    it 'runs the given function with logging enabled', ->
      as_eco.logging = false
      as_eco.with_logging ->
        expect(as_eco.logging).to.be.true


    it 'restores the logging to false if it was false before', ->
      as_eco.logging = false
      as_eco.with_logging ->
      expect(as_eco.logging).to.be.false

    it 'leaves the logging enabled if it was enabled before', ->
      as_eco.logging = true
      as_eco.with_logging ->
      expect(as_eco.logging).to.be.true
