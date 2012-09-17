#Asynchronous, streaming embedded CoffeeScript templates

AsEco does pretty much the same thing that [ECO templates](https://github.com/sstephenson/eco) templates do, with the following delicate differences:

*   __Streaming:__ Rather than rendering the template completely into a buffer first, and then outputting that buffer to the client, 
    AsEco templates output chunks of their content directly and immediately into the output stream as soon as that makes sense.

*   __Asynchronous:__ AsEco support calling asynchronous methods from within the template, 
    i.e. methods that don't do anything at the time, but return their result at a later time using a callback function.
    AsEco templates understand this paradigm and pause the output stream at this point until the callback method gets called. 
    The rendering continues normally after that.


Both features, combined with [Asynchronous Futures](https://github.com/kevgo/async_future.coffee),
allow a web server that uses AsEco templates to output the static headers of their response
immediately to the client browser, while waiting until data from the database is loaded. The remaining parts of the response are rendered
in chunks as soon as the required data becomes available from the backend. 
This gives the browser a chance to prefetch static assets of the web page (CSS, JavaScript) in parallel while the 
server generates the remaining response.


## Usage

Working examples are given in the [example](https://github.com/kevgo/as_eco/tree/master/examples) directory.

Here is an example CoffeeScript file that renders a template.

```coffeescript
# Load the required libraries.
AsyncFuture = require 'async_future.coffee'
AsEco = require 'as_eco'

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

```

Here is the corresponding template.
```php
This part is sent immediately.

<% async @user.get, user %>
This part is sent as soon as the server receives the user information from its backend.
<%= user %>

While we wait for the city data to become available, 
we can use CoffeeScript to define and massage data.
<% a = 1 %>
<%= a %>

<% async @city.get, city %>
This part is sent after the expensive backend operation to retrieve city data finishes.
<%= city %>
```
