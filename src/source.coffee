# External dependencies

fs     = require 'fs'
path   = require 'path'
mkdirp = require 'mkdirp'
xcolor = require 'xcolor'
coffee = require 'coffee-script'
uglify = require 'uglify-js'

# The Source class represents a file containing source code. It knows
# how to read a file in, compile it, transform it, and then write it
# out to a target file.

class Source

  # Initialization
  # -------------

  # Initilization consists of setting the timestamps to zero, then resolving
  # the file name and reading it in.
  constructor: (@options, @file = "") ->
    @writeTime = 0
    @compileTime = 0
    @modTime = 0

    if @file
      @inputFile = path.resolve file
      @read()

  # Actions
  # -------

  # Read in the source file from disk and store the number of lines for 
  # later use in reporting errors in joined filed.
  read: ->
    @src = fs.readFileSync @file, 'utf8'
    @lines = @src.split('\n').length
    @modTime = new Date().getTime()
    @setOutputPath()

  # Call the CoffeeScript compiler, and save the output. If there are any
  # errors, stash them for reporting later and continue on. If a source
  # map style result is returned, split it out appropriately.
  compile: ->
    try
      @error = false
      @compiled = coffee.compile @src, @getCompileOptions()
      @compileTime = new Date().getTime()
      
      if @compiled.js?
        @sourceMap = @compiled.v3SourceMap
        @compiled = @compiled.js
    
    catch err
      @error = err.toString().replace /on line \d/, ''
      @errorFile = @file
      line = /on line (\d)/.exec(err)
      @errorLine = if line?[1]? then line[1] else 0

  # Transform the compiled source by passing it through Uglify-JS.
  minify: ->
    result = uglify.minify @compiled, {fromString: true}
    @compiled = result.code

  # Determines where this source should be written out to, creates the dirs
  # if needed, and then output it. Finally, send a snazzy success message to
  # the console.
  write: ->
    @setOutputPath()
    mkdirp.sync path.dirname(@outputPath)
    fs.writeFileSync @outputPath, @compiled, 'utf8'
    @writeTime = new Date().getTime()

    @writeMap() if @options.sourceMap
      
    unless @options.silent
      xcolor.log "  #{(new Date).toLocaleTimeString()} - {{.boldCoffee}}Compiled{{/color}} {{.coffee}}#{@outputPath}"

  # Write out a .map file in the same directory as the compiled js.
  writeMap: ->
    mapOutput = @outputPath.replace '.js', '.map'
    fs.writeFileSync mapOutput, @sourceMap, 'utf8'

  # Utilities
  # ---------

  # Returns the currently set compiler options.
  getCompileOptions: ->
    header: @options.header
    bare: @options.bare
    literate: @isLiterate()
    filename: @file
    sourceMap: @options.sourceMap
    sourceRoot: path.dirname @file
    sourceFiles: [@file]
    generatedFile: @outputPath

  # Returns true if the source is Literate CoffeeScript
  isLiterate: ->
    /\.(litcoffee|coffee\.md)$/.test @file

  # Sends a log of this source's current error to the console.
  reportError: ->
    xcolor.log "  #{(new Date).toLocaleTimeString()} - {{bold}}{{.error}}#{@errorFile}:{{/bold}} #{@error} on line #{@errorLine}"  

  # Sets the output path for this source based on a combination of the input
  # file and the passed in options.
  setOutputPath: ->
    return if @outputPath

    base = path.basename @file
    base = base.substr 0, base.indexOf '.'
    fileName = base + '.js'
    dir = path.dirname @file

    if @options.output
      dir = dir.replace @inputFile, @options.output

    @outputPath = path.join dir, fileName

  # Returns true if this source has uncompiled changes.
  updated: ->
    @modTime >= @compileTime

  # Returns true if this source has unwritten compiled changes.
  outputReady: ->
    !@error and @compileTime >= @writeTime

# Exports
# -------

# Export the Source class.
module.exports = Source

