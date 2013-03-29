# Coffeebar

Coffeebar is a simplified build tool for CoffeeScript that makes compiling,
watching and concatenating your files a breeze. Coffeebar is built to be 
cross-platform from the ground up and can be used from the command line or
via it's public API.

### Features

* Robust file watching
* Cross-platform
* Minification
* Concatenation of multiple source files
* Shows the actual source line when concatenated files have a compile error

## Installation

Install globally via npm:

    $ npm install -g coffeebar

## Usage

    Usage: coffeebar [options] [path ...]

    Options:

      -h, --help           output usage information
      -V, --version        output the version number
      -b, --bare           compile without a top-level function wrapper
      -m, --minify         minify output files
      -o, --output <path>  output path
      -s, --silent         suppress console output
      -w, --watch          watch files for changes

#### Examples

Compile a single file:
    
    $ coffeebar test.coffee

Compile an entire directory tree to an output directory:
    
    $ coffeebar src -o lib

Compile and join all input to a single file:
    
    $ coffeebar src -o joined.js

Compile and watch for changes:

    $ coffeebar src -o lib -w

## API

#### coffeebar(inputPaths, [options])

Compiles all .coffee files found in `inputPaths`, which can be a single string or an array of strings. 

##### Options:

* `bare` - (boolean) CoffeeScript compiler option which omits the top-level function wrapper if set to true.
* `minify` - (boolean) Minify output files. Defaults to false.
* `output` - (string) The path to the output file. If the path has a file extension, all files will be joined at that location. Otherwise, the path is assumed to be a directory.
* `silent` - (boolean) Suppress all console output. Defaults to true.
* `watch` - (boolean) Watch all files and directories for changes and recompile automatically. Defaults to false.

##### Example:

    var coffeebar = require('coffeebar')

    coffeebar('src', {output: 'lib/app.js'})

## Running the tests

To run the test suite, invoke the following commands in the repository:

    $ npm install
    $ npm test

## License

(The MIT License)

Copyright (c) 2013 Charles Moncrief <<cmoncrief@gmail.com>>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.