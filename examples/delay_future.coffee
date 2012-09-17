AsyncFuture = require '../../async_future.coffee'
AsEco = require '../src/as_eco'

delay_function = (delay, result, done) -> setTimeout((-> done(result)), delay)
user_loader = new AsyncFuture delay_function, 1000, 'John Doe'
city_loader = new AsyncFuture delay_function, 2000, 'Los Angeles'

template_name = './template.aseco'
console.log '[rendering start]\n'
AsEco.render_file template_name, {user: user_loader, city: city_loader}, console.log, -> console.log '\n\n[rending finished]'

