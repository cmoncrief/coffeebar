
fs       = require 'fs'
path     = require 'path'
beholder = require 'beholder'
coffee   = require 'coffee-script'
glob     = require 'glob'
mkdirp   = require 'mkdirp'
xcolor   = require 'xcolor'

Source   = require './source'

class Coffeebar

  constructor: (@inputPaths, @options = {}) ->
    @sources = []
    @options.watch ?= false
    @options.silent ?= true
    @options.minify ?= false
    @options.join = true if @options.output and path.extname(@options.output)

    @options.coffeeOpts = {}
    @options.coffeeOpts.bare = @options.bare or false
    @options.coffeeOpts.header = @options.header or true

    @initColors()
    @initPaths()

    @start()

  initPaths: ->
    unless Array.isArray(@inputPaths) then @inputPaths = [@inputPaths]

    for inputPath, i in @inputPaths
      unless path.extname(inputPath)
        @inputPaths[i] = "#{inputPath}/**/*.coffee"

    @inputPaths = (i for i in @inputPaths when path.extname(i) is '.coffee')

  addSources: ->
    for inputPath in @inputPaths
      files = glob.sync inputPath
      @sources.push(new Source(@options, file)) for file in files

  start: ->
    @addSources()
    @build()

    if @options.watch
      @watch i for i in @inputPaths

  build: ->
    @compileSources()
    @reportErrors()
    @writeSources()
  
  compileSources: ->
    @outputs = if @options.join then @joinSources() else @sources

    source.compile() for source in @outputs when source.modTime >= source.compileTime

  reportErrors: ->
    if @options.join and @outputs[0].error
      offset = 0
      for source in @sources
        if offset + source.lines > @outputs[0].errorLine
          errorFile = source.file
          break
        else
          offset += source.lines

      @outputs[0].errorLine = @outputs[0].errorLine - offset
      @outputs[0].errorFile = errorFile

    source.reportError() for source in @outputs when source.error

  writeSources: ->
    source.write() for source in @outputs when !source.error and source.compileTime >= source.writeTime

  joinSources: ->
    joinSrc = ""
    joinSrc = joinSrc.concat(i.src + "\n") for i in @sources

    joinSource = new Source(@options)
    joinSource.src = joinSrc
    joinSource.outputPath = @options.output
    [joinSource]

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

  getSource: (file) ->
    return i for i in @sources when i.file is file

  initColors: ->
    xcolor.addStyle coffee     : 'chocolate'
    xcolor.addStyle boldCoffee : ['bold', 'chocolate']
    xcolor.addStyle error      : 'crimson'

module.exports = (inputPaths, options) ->
  new Coffeebar inputPaths, options

