#!/bin/sh
echo Combine CSS files...
cat vanilla-terminal.css todo.css > app.css
echo Add polyfills and vanilla-terminal...
cat polyfills.js vanilla-terminal.js > app.js
echo Compile app.js.rb for web...
opal --require date --require json --compile app.js.rb | grep -v "//# sourceMappingURL" >> app.js
echo Compress/optimize app.js...
java -jar closure-compiler.jar --isolation_mode IIFE --warning_level QUIET --js app.js --js_output_file app.min.js
mv app.min.js app.js
