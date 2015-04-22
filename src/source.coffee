# External dependencies

fs        = require 'fs'
path      = require 'path'
mkdirp    = require 'mkdirp'
xcolor    = require 'xcolor'
coffee    = require 'coffee-script'
uglify    = require 'uglify-js'
sourcemap = require 'source-map'

# The Source class represents a file containing source code. It knows
# how to read a file in, compile it, transform it, and then write it
# out to a target file.

class Source

  # Initialization
  # -------------

  # Initilization consists of setting the timestamps to zero, then resolving
  # the file name and reading it in.
  constructor: (@options, @file = "", @inputPath = "") ->
    @writeTime = 0
    @compileTime = 0
    @modTime = 0
    @inputPath or= @file

    if @file
      @inputFile = path.resolve @file
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
        @sourceMap = JSON.parse @compiled.v3SourceMap
        @compiled = @compiled.js

    catch err
      @error = err.toString()
      @errorFile = @file
      @errorLine = err.location.first_line

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

    @writeMapSource() if @options.sourceMap and @options.output and !@options.join

    unless @options.silent
      xcolor.log "  #{(new Date).toLocaleTimeString()} - {{.boldCoffee}}Compiled{{/color}} {{.coffee}}#{@outputPath}"

  # Writes out the uncompiled source file. This is used for source mapping to place
  # a copy of the original file next to the compiled version.
  writeSource: (base) ->
    outputPath = path.join base, @file
    mkdirp.sync path.dirname(outputPath)
    fs.writeFileSync outputPath, @src, 'utf8'

  # Write out the uncompiled source file side-by-side with the output file.
  writeMapSource: ->
    mapOutput = @outputPath.replace '.js', '.coffee'
    fs.writeFileSync mapOutput, @src, 'utf8'

  # Append the compiled output with a source map comment.
  writeMapComment: (map) ->
    map or= JSON.stringify @sourceMap
    commentMap = new Buffer(map).toString('base64')
    commentMap = "//@ sourceMappingURL=data:application/json;base64,#{commentMap}"
    @compiled = "#{@compiled}\n#{commentMap}"

  # Utilities
  # ---------

  # Returns the currently set compiler options.
  getCompileOptions: ->
    header: @options.header
    bare: @options.bare
    literate: @isLiterate()
    filename: @file
    sourceMap: @options.sourceMap
    sourceFiles: [if @options.join then @file else path.basename @file]
    generatedFile: @outputPath

  # Returns true if the source is Literate CoffeeScript
  isLiterate: ->
    /\.(litcoffee|coffee\.md)$/.test @file

  # Sends a log of this source's current error to the console.
  reportError: ->
    xcolor.log "  #{(new Date).toLocaleTimeString()} - {{bold}}{{.error}}#{@errorFile}:{{/bold}} #{@error} on line #{@errorLine + 1}"

  # Sets the output path for this source based on a combination of the input
  # file and the passed in options.
  setOutputPath: ->
    return if @outputPath

    base = path.basename @file
    base = base.substr 0, base.indexOf '.'
    fileName = base + '.js'
    dir = path.dirname @file

    if @options.output
      if @inputPath[0] is path.sep
        baseInputDir = @inputPath.replace '**/*.{coffee,litcoffee,coffee.md}', ''
        baseInputDir = baseInputDir.replace new RegExp("#{path.basename(baseInputDir)}/?$"), ''
        baseInputDir = path.normalize baseInputDir
        baseOutputDir = dir.replace baseInputDir, ''
        baseFragment = baseOutputDir.substr 0, baseOutputDir.indexOf(path.sep)
        baseDir = baseOutputDir.replace new RegExp("^#{baseFragment}"), ''
        dir = if baseFragment then path.join(@options.output, baseDir) else @options.output
      else if @inputPath.indexOf path.sep
        baseDir = @inputPath.substr 0, @inputPath.indexOf(path.sep)
        dir = dir.replace new RegExp("^#{baseDir}"), @options.output
      else
        dir = @options.output

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
