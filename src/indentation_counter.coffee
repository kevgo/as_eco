require 'ruby.coffee'


# Allows to count how much source code should be indented 
# in flexible ways necessary for CoffeeScript.
class IndentationCounter

  constructor: ->

    # Collection of the indentation tokens set by 'indent()'.
    @indentation_tokens = []


  # Increases the indentation level by the given units.
  indent: (units = 1)  ->
    @indentation_tokens.push units


  # Provides the current indentation level.
  indentation_level: ->
    @indentation_tokens.inject 0, (sum, token) -> sum + token


  undent: ->
    throw 'Error: Nothing to undent.' if @indentation_tokens.length == 0
    @indentation_tokens = @indentation_tokens.slice 0, -1



module.exports = IndentationCounter
