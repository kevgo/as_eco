[expect, sinon, chai] = require './test_helper'


Compiler = require '../src/compiler'

chai.Assertion.addMethod 'equal_string', (expected) ->
  actual = @_obj
  if actual != expected
    throw { expected: expected, actual: actual }



describe 'Compiler', ->

  describe 'next_segment', ->

    it 'returns the next segment', ->
      compiler = new Compiler 'name', ['one', 'two']
      expect(compiler.next_segment()).to.equal 'one'
      expect(compiler.next_segment()).to.equal 'two'


  describe 'compile', ->

    describe 'static text', ->
      it 'renders text into the out stream', ->
        compiler = new Compiler 'name', [ { type: 'text', data: 'one'} ]
        expect(compiler.compile()).to.equal """
                                        @render_functions['name'] = (out, done, escape) ->
                                          __this__ = this
                                          out(\"one\")
                                          done()

                                        """

      it 'converts newlines into spaces', ->
        compiler = new Compiler 'name', [ { type: 'text', data: "one\n\ntwo\n\n"} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 out(\"onetwo\")
                                                 done()

                                               """


    describe 'expressions', ->
      it 'renders javascript expressions into the out stream', ->
        compiler = new Compiler 'name', [ { type: 'exp', data: 'a = 1'} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 a = 1
                                                 done()

                                               """


    describe 'output', ->
      it 'renders javascript output into the out stream', ->
        compiler = new Compiler 'name', [ { type: 'out', data: 'foo'} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 out(escape(foo))
                                                 done()

                                               """

      it 'html-escapes javascript output', ->
        compiler = new Compiler 'name', [ { type: 'out', data: 'foo'} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 out(escape(foo))
                                                 done()

                                               """

      it 'makes elements of the data stream available through the @ character', ->
        compiler = new Compiler 'name', [ { type: 'out', data: '@foo'} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 out(escape(__this__.foo))
                                                 done()

                                               """

      it 'renders javascript else clauses into the out stream', ->
        segments = [ { type: 'exp', data: 'if a == 1:' },
                     { type: 'exp', data: 'foo' },
                     { type: 'else' },
                     { type: 'exp', data: 'bar' },
                     { type: 'end', data: '' } ]
        compiler = new Compiler 'name', segments
        expect(compiler.compile()).to.equal        """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 if a == 1
                                                   foo
                                                 else
                                                   bar
                                                 done()

                                               """

    describe 'loops', ->
      it 'render iterations over array variables', ->
        segments = [ { type: 'for', data: 'user in users:' },
                     { type: 'out', data: 'user' },
                     { type: 'end', data: '' } ]
        compiler = new Compiler 'name', segments
        expect(compiler.compile()).to.equal        """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 for user in users
                                                   do (user) ->
                                                     out(escape(user))
                                                 done()

                                               """

      it 'render iterations over hard-coded arrays', ->
        segments = [ { type: 'for', data: 'i in [1,2]:' },
                     { type: 'out', data: 'i' },
                     { type: 'end', data: '' } ]
        compiler = new Compiler 'name', segments
        expect(compiler.compile()).to.equal        """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 for i in [1,2]
                                                   do (i) ->
                                                     out(escape(i))
                                                 done()

                                               """

    describe 'asynchronous expressions', ->

      it 'renders simple expressions', ->
        compiler = new Compiler 'name', [ { type: 'async', data: '@user.get, user'} ]
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 __this__.user.get (user) ->
                                                   done()

                                               """

      it 'closes several layers of async functions properly', ->
        segments = [ { type: 'async', data: '@user.get, user'},
                     { type: 'async', data: 'city.get, city'} ]
        compiler = new Compiler 'name', segments
        expect(compiler.compile()).to.equal_string """
                                               @render_functions['name'] = (out, done, escape) ->
                                                 __this__ = this
                                                 __this__.user.get (user) ->
                                                   city.get (city) ->
                                                     done()

                                               """


  describe 'spaces', ->

    it 'returns 2 spaces normal indentation', ->
      compiler = new Compiler 'name', []
      expect(compiler.spaces()).to.equal '  '

    it 'returns 4 spaces for the first indentation level', ->
      compiler = new Compiler 'name', []
      compiler.callback_level.indent()
      expect(compiler.spaces()).to.equal '    '

    it 'returns 6 spaces for the second indentation level', ->
      compiler = new Compiler 'name', []
      compiler.callback_level.indent 2
      expect(compiler.spaces()).to.equal '      '
