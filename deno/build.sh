#!/bin/sh
# gem install opal -v 1.2.0
cp deps.js todo.js
opal --require date --require json --compile todo.js.rb | grep -v "//# sourceMappingURL" >> todo.js
deno bundle todo.js todo.js
