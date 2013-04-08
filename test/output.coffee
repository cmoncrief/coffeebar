assert    = require 'assert'
fs        = require 'fs'
path      = require 'path'
coffeebar = require '../lib/coffeebar'
rimraf    = require 'rimraf'

fixturePath = path.join __dirname, 'fixtures/output'

inputFile = path.join fixturePath, 'input.coffee'
outputFile = path.join fixturePath, 'input.js'
inputDir = path.join fixturePath, 'input'
outputDir = path.join fixturePath, 'output'

files = [
  "numbers.js"
  "sub/letters.js"
  "sub/subsub/letters2.js"
]

describe 'Output', ->

  before ->
    removeTestFiles()

  it 'should write to the same directory', ->
    coffeebar inputFile
    assert fs.existsSync outputFile

  it 'should write from an input dir to an output dir', ->
    coffeebar inputDir, {output: outputDir}
    for file in files
      assert fs.existsSync path.join(outputDir, file)

  it 'should write from an input file to an output dir', ->
    coffeebar inputFile, {output: outputDir}
    assert fs.existsSync path.join(outputDir, "input.js")

  after ->
    removeTestFiles()

removeTestFiles = ->
  try fs.unlinkSync outputFile
  try fs.unlinkSync path.join(outputDir, "input.js")
  rimraf.sync "#{fixturePath}/output"
