
fs     = require 'fs'
path   = require 'path'
mkdirp = require 'mkdirp'
xcolor = require 'xcolor'
coffee = require 'coffee-script'
util = require 'util'

class Source

  constructor: (@options, @file = "") ->
    @writeTime = 0
    @compileTime = 0
    @modTime = 0

    if @file
      @inputFile = path.resolve file
      @read()

  compile: ->
    try
      @error = false
      @compiled = coffee.compile @src, @options.coffeeOpts
      @compileTime = new Date().getTime()
    catch err
      @error = err.toString().replace /on line \d/, ''
      @errorFile = @file
      line = /on line (\d)/.exec(err)
      @errorLine = if line[1] then line[1] else 0

  reportError: ->
    xcolor.log "  #{(new Date).toLocaleTimeString()} - {{bold}}{{.error}}#{@errorFile}:{{/bold}} #{@error} on line #{@errorLine}"  

  read: ->
    @src = fs.readFileSync @file, 'utf8'
    @lines = @src.split('\n').length
    @modTime = new Date().getTime()

  write: ->
    @setOutputPath()
    mkdirp.sync path.dirname(@outputPath)
    fs.writeFileSync @outputPath, @compiled, 'utf8'
    @writeTime = new Date().getTime()

    unless @options.silent
      xcolor.log "  #{(new Date).toLocaleTimeString()} - {{.boldCoffee}}Compiled{{/color}} {{.coffee}}#{@outputPath}"

  setOutputPath: ->
    return if @outputPath

    fileName = path.basename(@file, '.coffee') + '.js'
    dir = path.dirname @file

    if @options.output
      dir = dir.replace @inputFile, @options.output

    @outputPath = path.join dir, fileName


module.exports = Source

