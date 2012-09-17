CoffeeScript = require 'coffee-script'
Compiler = require './compiler'
Fs = require 'fs'
Parser = require './parser'


# An engine for rendering AsEjs templates.
class AsEco

  constructor: ->

    # The render functions for the different templates.
    @render_functions = {}

    # Whether to log to the console.
    @logging = false


  # Compiles the given template into a render function.
  compile: (name, text) ->

    # Parse the template into segments.
    segments = Parser.parse text

    # Build the render function.
    compiler = new Compiler name, segments
    func = compiler.compile()
    if @logging
      console.log ''
      console.log func
    js_func = CoffeeScript.compile func
    eval js_func


  compile_file: (filename, done) ->
    Fs.readFile filename, (err, data) =>
      if err
        throw "Cannot read '#{filename}': #{err}"
      @compile filename, data.toString()
      done()


  # HTML escapes the given string.
  escape: (text) ->
    new String(text)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\x22/g, '&quot;')

  # Returns whether the given template has been compiled already.
  has_compiled_template: (template_name) ->
    !!@render_functions[template_name]


  # Renders the given data into the precompiled template with the given name.
  render: (template_name, data, out_stream, done_cb) ->

    # Get the render function.
    render_function = @render_functions[template_name]
    unless render_function
      throw "ERROR: template '#{template_name}' has not been parsed yet."

    # Run the render function.
    render_function.call data, out_stream, done_cb, @escape


  # Renders the given template file with the given data into the given output stream.
  # Compiles the template if that hasn't happened yet.
  render_file: (filename, data, out_stream, done_cb) ->
    
    # Compile the template if it isn't compiled yet.
    if @has_compiled_template filename
      @render filename, data, out_stream, done_cb
    else
      @compile_file filename, =>
        @render filename, data, out_stream, done_cb


  # Resets this object to its pristine state.
  reset: ->
    @render_functions = {}


  # Runs the given function with logging temporality enabled.
  with_logging: (func) ->
    old_logging = @logging
    @logging = true
    func()
    @logging = old_logging


module.exports = new AsEco()
