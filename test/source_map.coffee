assert    = require 'assert'
fs        = require 'fs'
path      = require 'path'
rimraf    = require 'rimraf'
coffeebar = require '../lib/coffeebar'

fixturePath = path.join __dirname, 'fixtures'

files = [
  'numbers'
  'sub/letters'
  'sub/subsub/letters2'
]

process.chdir "#{fixturePath}/map"

describe 'Source maps', ->

  before ->
    removeTestFiles()

  it 'should create a source map for a single file', ->
    coffeebar "letters.coffee", {sourceMap: true}
    
    testFile = fs.readFileSync "#{fixturePath}/map/letters.js", 'utf8'
    controlFile = fs.readFileSync "#{fixturePath}/control/mapletters.js", 'utf8'
    
    assert.equal testFile, controlFile

  it 'should create source maps for an output tree', ->
    testFiles = []; testFileSources = []; controlFiles = []
    coffeebar "compile", {sourceMap: true, output: "output"}
    
    for file in files
      testFiles.push fs.readFileSync "#{fixturePath}/map/output/#{file}.js", 'utf8'
      testFileSources.push fs.readFileSync "#{fixturePath}/map/output/#{file}.coffee", 'utf8'
      controlFiles.push fs.readFileSync "#{fixturePath}/control/map/#{file}.js", 'utf8'

    assert.equal files.length, testFiles.length
    assert.equal files.length, testFileSources.length
    assert.equal files.length, controlFiles.length

    for file, i in testFiles
      assert.equal file, controlFiles[i]

  it 'should create source maps for a joined file', ->
    coffeebar "compile", {sourceMap: true, output: "join.js"}
    
    testFile = fs.readFileSync "#{fixturePath}/map/join.js", 'utf8'
    controlFile = fs.readFileSync "#{fixturePath}/control/mapjoin.js", 'utf8'

    assert fs.existsSync "#{fixturePath}/map/join_mapsrc"
    assert.equal testFile, controlFile

  after ->
    removeTestFiles()

removeTestFiles = ->
  try fs.unlinkSync "#{fixturePath}/map/letters.js"
  try fs.unlinkSync "#{fixturePath}/map/join.js"
  try rimraf.sync "#{fixturePath}/map/join_mapsrc"
  try rimraf.sync "#{fixturePath}/map/output"
