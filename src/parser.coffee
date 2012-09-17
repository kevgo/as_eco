# Parses AsEjs templates into a data structure in memory.
class AsEjsParser

  # Parses the given text into fully recognized segments.
  # This is the main method.
  @parse: (text) ->
    @recognize_segments @segment text


  # Segments the given text into TEXT and JS segments.
  @segment: (text) ->
    result = []

    # Whether we are in static text or inside a '<% ... %>' block right now.
    in_js = no

    # The current search pointer.
    search_ptr = 0

    text_length = text.length

    loop
      if !in_js
        # We are in static text.
        
        js_start_tag_pos = text.indexOf '<%', search_ptr
        if js_start_tag_pos == -1
          # We have reached the end of the string --> append the text segment and done.
          data = text.substring search_ptr
          result.push type: 'text', data: data if data
          return result
        else
          # We have reached a JS start tag.
          data = text.substring search_ptr, js_start_tag_pos
          result.push type: 'text', data: data if data
          search_ptr = js_start_tag_pos + 2
          in_js = yes
      else
        # We are in JS text.
        
        js_end_tag_pos = text.indexOf '%>', search_ptr
        if js_end_tag_pos == -1
          throw "ERROR: unclosed Javascript end tag at line #{search_ptr}."
        data = text.substring search_ptr, js_end_tag_pos
        result.push type: 'js', data: data
        search_ptr = js_end_tag_pos + 2
        in_js = no

  
  # Recognizes the given stack of TEXT and JS segments.
  @recognize_segments: (segments) ->
    result = []
    for segment in segments
      if segment.type == 'text'
        result.push segment
        continue

      if segment.type == 'js'
        partitions = segment.data.partition /[^\s]+/
        partitions[2] = partitions[2].trim()
        entry = { type: null, data: partitions[2] }
        switch partitions[1]
          when '=' then entry.type = 'out'
          when 'else:' then entry.type = 'else'
          when 'end' then entry.type = 'end'
          when 'for' then entry.type = 'for'
          when 'async' then entry.type = 'async'
          else
            entry = type: 'exp', data: "#{partitions[1]} #{partitions[2]}".trim()
        result.push entry
        continue

      throw "ERROR: unknown segment type: '#{segment.type}'"
    result


module.exports = AsEjsParser

