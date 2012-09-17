Builder = require './builder'
require 'ruby.coffee'
IndentationCounter = require './indentation_counter'


# Compiles the given segments into a render function.
class Compiler

  constructor: (@name, @segments) ->
    @builder = new Builder
    @callback_level = new IndentationCounter
    @segments_length = @segments.length
    @current_step = 0


  # Returns the next segment to process.
  next_segment: ->
    @segments[@current_step++]


  # Builds the render string.
  compile: ->
    @builder.append "@render_functions['#{@name}'] = (out, done, escape) ->\n"
    @builder.append "  __this__ = this\n"

    # Compile all the segments.
    while @current_step < @segments_length
      segment = @next_segment()
      this["compile_#{segment.type}"](segment.data)
 
    # We are done compiling the segments --> call 'done()'.
    @builder.append "#{@spaces()}done()\n"

    # Close all the open callbacks.
    while @callback_level > 0
      @callback_level.undent()

    # Return the result.
    @builder.result()


  # Returns the correct amount of spaces to prepend to each line.
  spaces: ->
    new Array(@callback_level.indentation_level()+2).join '  '


  # Compiles the given text segment.
  compile_text: (data) ->
    data = data.replace /\n/g, ''
    data = data.replace /\s+/g, ' '
    @builder.append "#{@spaces()}out(\"#{data}\")\n"


  # Compiles the given javascript expression.
  compile_exp: (data) ->
    @builder.append @spaces()
    data = data.replace '@', '__this__.'
    if data.ends_with ':'
      data = data.substring 0, data.length-1
      @callback_level.indent()
    @builder.append data
    @builder.append '\n'


  # Compiles the given else-clause
  compile_else: (data) ->
    @callback_level.undent()
    @builder.append @spaces()
    @builder.append "else\n"
    @callback_level.indent()


  # Compiles the given end-clause
  compile_end: (data) ->
    @callback_level.undent()


  # Compiles the given end-clause
  compile_for: (data) ->
    matches = /^(\w+) in ([^\s]+)$/.exec data
    throw "Unknown for loop: '#{data}'" if matches.length != 3
    variable_name = matches[1]
    array_name = matches[2]
    if array_name.ends_with ':'
      array_name = array_name.substring 0, array_name.length-1
    else
      throw "Error: FOR loop must end with ':'"
    @builder.append "#{@spaces()}for #{variable_name} in #{array_name}\n"
    @builder.append "#{@spaces()}  do (#{variable_name}) ->\n"
    @callback_level.indent 2


  # Compiles the given JSOUT expression.
  compile_out: (data) ->
    data = data.replace '@', '__this__.'
    @builder.append @spaces()
    @builder.append "out(escape(#{data.trim()}))\n"


  # Compiles the given asynchronous JS expression.
  compile_async: (data) ->
    data = data.replace '@', '__this__.'
    parts = data.split ','
    @builder.append @spaces()
    @builder.append "#{parts[0].trim()} (#{parts[1].trim()}) ->\n"
    @callback_level.indent()



module.exports = Compiler
