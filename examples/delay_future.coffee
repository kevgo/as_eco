# Load the required libraries.
AsyncFuture = require 'async_future.coffee'
AsEco = require '../src/as_eco'

# Simulate slow database operations.
simulate_delay = (delay, result, done_callback) ->
  setTimeout (-> done_callback(result)), delay
user_loader = new AsyncFuture simulate_delay, 1000, 'John Doe '
city_loader = new AsyncFuture simulate_delay, 2000, 'Los Angeles'


# The name of the template file to render.
template_filename = './template.as_eco'

# The data that should be rendered into the template.
data = {user: user_loader, city: city_loader}

# The template writes output by calling this function.
out_stream = console.log

# The template calls this function when it is done rendering.
done_callback = -> console.log '\n\n[rending finished]'

console.log '[rendering start]\n'
AsEco.render_file template_filename,
                  data,
                  console.log,
                  done_callback

