# Coffeebar
# ---------
# Copyright (c) 2013 Charles Moncrief <cmoncrief@gmail.com>
#
# MIT Licensed

# Coffeebar is a minimalistic CoffeeScript build utility. It supports file
# watching, minification and concatenation of source files. Coffeebar is
# available as a command line utility and can also be used directly from the
# public API.

# External dependencies.

fs        = require 'fs'
path      = require 'path'
beholder  = require 'beholder'
coffee    = require 'coffee-script'
glob      = require 'glob'
mkdirp    = require 'mkdirp'
xcolor    = require 'xcolor'
Source    = require './source'
sourcemap = require 'source-map'

# Valid CoffeeScript file extentsions
exts     = ['coffee', 'litcoffee', 'coffee.md']

# The Coffebar class is the main entry point of the API. Creating a new
# instance will initialize and kick off a build.

class Coffeebar

  # Initialization
  # --------------

  # Initialize the default options and the color scheme. The join option is
  # implied rather then specific. Once initial setup is completed, kick off
  # the initial build.
  constructor: (@inputPaths, @options = {}) ->
    @sources = []
    @options.watch ?= false
    @options.silent ?= true
    @options.minify ?= false
    @options.extSourceMap ?= false
    @options.extSourceMap = false if @options.minify
    @options.sourceMap ?= false
    @options.sourceMap = false if @options.minify
    @options.sourceMap = @options.sourceMap or @options.extSourceMap
    @options.join = true if @options.output and path.extname(@options.output)

    @options.bare ?= false
    @options.header ?= true

    @initColors()
    @initPaths()

    @start()

  # Prepare the specified input paths to be scanned by glob by assuming that
  # we actually want to compile the entire directory tree that was passed in,
  # unless an actual filename was passed in.
  initPaths: ->
    unless Array.isArray(@inputPaths) then @inputPaths = [@inputPaths]

    for inputPath, i in @inputPaths
      @inputPaths[i] = inputPath = path.normalize inputPath
      unless path.extname(inputPath)
        @inputPaths[i] = "#{inputPath}/**/*.{#{exts}}"

  # Find all the src files in the input trees and create a new representation
  # of them via the Source class.
  addSources: ->
    for inputPath in @inputPaths
      files = glob.sync inputPath
      @sources.push(new Source(@options, file, inputPath)) for file in files

  # Start-up the initial process by adding the sources, building them,
  # and starting a watch on them if specified. This is only called once,
  # subsequent builds will be called directly from the watch process.
  start: ->
    @addSources()
    @build()

    if @options.watch
      @watch i for i in @inputPaths

  # Build
  # -----

  # Compile and write out all of the sources in our collection, transforming
  # and reporting errors along the way.
  build: ->
    @offsetSources()
    @compileSources()
    @mapSources() if @options.sourceMap
    @minifySources() if @options.minify
    @reportErrors()
    @writeSources()
    @writeJoinSources() if @options.sourceMap and @options.join

  # Compile each source in the collection if it has been updated
  # more recently than the last time it was written out. If this
  # build is targetting a joined file, join all of the sources
  # prior to compilation.
  compileSources: ->
    @outputs = if @options.join then @joinSources() else @sources
    source.compile() for source in @outputs when source.updated

  # Minify each source in the collection if it was compiled without
  # errors more recently than it was written out.
  minifySources: ->
    source.minify() for source in @outputs when source.outputReady()
  
  # Source maps
  # -----------

  # Append the source map comments to each output file. In the case of
  # a joined file, we take the mappings that came out of the compiler
  # and remap them to the original source files, rather than the joined
  # src file that we sent to the compiler.
  mapSources: ->
    unless @options.join
      unless @options.extSourceMap
        source.writeMapComment() for source in @sources
      else
        source.writeMapCommentExt() for source in @sources
      return

    return unless @outputs[0].sourceMap
    smOld = new sourcemap.SourceMapConsumer @outputs[0].sourceMap
    smNew = new sourcemap.SourceMapGenerator {file: (path.basename smOld.file), sourceRoot: "#{path.basename(@options.output, '.js')}_mapsrc"}
    smOld.eachMapping (map) => smNew.addMapping(@offsetMapping map)

    unless @options.extSourceMap
      @outputs[0].writeMapComment smNew.toString()
    else
      @outputs[0].writeMapCommentExt smNew.toString()

  # After compilation, report each error that was logged. In the event
  # that this is a joined output file, use the line number offset to
  # detect which input file the error actually occurred in.
  reportErrors: ->
    if @options.join and @outputs[0].error
      source = @getOriginalSource @outputs[0].errorLine
      @outputs[0].errorLine = @outputs[0].errorLine - source.offset
      @outputs[0].errorFile = source.file

    source.reportError() for source in @outputs when source.error

  # Write out each source in the collection if it was compiled without
  # error more recently than it was written out.
  writeSources: ->
    source.write() for source in @outputs when source.outputReady()

  # After writing out a joined output file with source maps enabled we
  # write out a special mapping directory next to it that contains all of
  # the original source files. The source map itself points to this directory
  # rather than the original files.
  writeJoinSources: ->
    outputPath = path.join path.dirname(@options.output), "#{path.basename(@options.output, '.js')}_mapsrc"
    source.writeSource(outputPath) for source in @sources when source.outputReady()

  # Watch
  # -----

  # Watch an input path for changes, additions and removals. When
  # an event is triggered, add or remove the source and kick off
  # a build.
  watch: (inputPath) ->
    watcher = beholder inputPath

    watcher.on 'change', (file) =>
      source = @getSource file
      source.read()
      @build()

    watcher.on 'new', (file) =>
      @sources.push(new Source(@options, file))
      @build()

    watcher.on 'remove', (file) =>
      @sources = (i for i in @sources when i.file isnt file)
      @build() if @options.join

  # Utilities
  #----------

  # Record the line offsets for each source file for later use.
  offsetSources: ->
    offset = 0
    for source in @sources
      source.offset = offset
      offset += source.lines

  # Retrieves the original source from a joined line number.
  getOriginalSource: (line) ->
    for source in @sources
      return source if source.offset + source.lines > line

  # Remaps a source mappping from the joined version to the original files.
  offsetMapping: (map) ->
    source = @getOriginalSource map.originalLine - 1
    newMap = 
      generated: {line: map.generatedLine, column: map.generatedColumn}
      original: {line: map.originalLine - source.offset, column: map.originalColumn}
      source: source.file

  # Join all sources by concatenating the input src code and return
  # an array with only the newly joined source element for output.
  joinSources: ->
    joinSrc = ""
    joinSrc = joinSrc.concat(i.src + "\n") for i in @sources

    joinSource = new Source(@options)
    joinSource.src = joinSrc
    joinSource.outputPath = @options.output
    [joinSource]

  # Retrieves the source in our collection by file name.
  getSource: (file) ->
    return i for i in @sources when i.file is file

  # Initialize our CLI theme with some sharp looking colors.
  initColors: ->
    xcolor.addStyle coffee     : 'chocolate'
    xcolor.addStyle boldCoffee : ['bold', 'chocolate']
    xcolor.addStyle error      : 'crimson'

# Exports
# -------

# Export a new instance of Coffeebar.
module.exports = (inputPaths, options) ->
  new Coffeebar inputPaths, options

