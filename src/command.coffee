program   = require 'commander'
coffeebar = require './coffeebar'

module.exports.run =  ->

  program
    .version('0.1.0')
    .usage('[options] [path ...]')
    .option('-b, --bare', 'compile without a top-level function wrapper')
    .option('-m, --minify', 'minify output files')
    .option('-o, --output <path>', 'output path')
    .option('-s, --silent', 'suppress console output')
    .option('-w, --watch', 'watch files for changes')

    program.parse process.argv

    options =
      output  : program.output
      watch   : program.watch
      silent  : program.silent || false
      minify  : program.minify
      bare    : program.bare

    console.log '' unless options.silent
    coffeebar program.args, options
    console.log '' unless options.silent
