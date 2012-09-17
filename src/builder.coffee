# Builds a JS string that when evaled executes the rendering process.
class Builder

  constructor: ->
    @content = []

  append: (text) ->
    @content.push text
    @

  result: ->
    @content.join ''


module.exports = Builder
