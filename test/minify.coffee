assert    = require 'assert'
fs        = require 'fs'
path      = require 'path'
coffeebar = require '../lib/coffeebar'

fixturePath = path.join __dirname, 'fixtures'

describe 'Minify', ->

  before ->
    try fs.unlinkSync "#{fixturePath}/compile/numbers.min.js"

  it 'should minify an output file', ->

    outputPath = "#{fixturePath}/compile/numbers.min.js"
    coffeebar "#{fixturePath}/compile/numbers.coffee", {minify: true, output: outputPath}

    testFile = fs.readFileSync "#{fixturePath}/compile/numbers.min.js", 'utf8'
    controlFile = fs.readFileSync "#{fixturePath}/control/numbers.min.js", 'utf8'
    
    assert testFile.length
    assert.equal testFile, controlFile

  after ->
    try fs.unlinkSync "#{fixturePath}/compile/numbers.min.js"