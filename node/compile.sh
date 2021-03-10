#!/bin/sh
echo Compile todo.js.rb for nodejs...
opal --require date --require json --compile todo.js.rb | grep -v "//# sourceMappingURL" > todo.js
echo Compress/optimize todo.js...
java -jar closure-compiler.jar --isolation_mode IIFE --warning_level QUIET --js todo.js --js_output_file todo.min.js
mv todo.min.js todo.js