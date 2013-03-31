# External dependencies

program   = require 'commander'
coffeebar = require './coffeebar'

# The Coffeebar command line utility. At a minimum, this command will compile
# an input CoffeeScript file or directory tree into JavaScript files. Additional 
# actions such as minification, joining and file watching can be specified here 
# as well as compiler options.

module.exports.run =  ->

  program
    .version('0.3.0')
    .usage('[options] [path ...]')
    .option('-b, --bare', 'compile without a top-level function wrapper')
    .option('-m, --minify', 'minify output files')
    .option('-M, --map', 'create source maps')
    .option('-o, --output <path>', 'output path')
    .option('-s, --silent', 'suppress console output')
    .option('-w, --watch', 'watch files for changes')

    program.parse process.argv

    options =
      output    : program.output
      watch     : program.watch
      silent    : program.silent || false
      minify    : program.minify
      sourceMap : program.map
      bare      : program.bare

    console.log '' unless options.silent
    coffeebar program.args, options
    console.log '' unless options.silent
