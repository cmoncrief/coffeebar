assert    = require 'assert'
fs        = require 'fs'
path      = require 'path'
coffeebar = require '../lib/coffeebar'

fixturePath = path.join __dirname, 'fixtures'

describe 'Literate', ->

  before ->
    try fs.unlinkSync "#{fixturePath}/literate/numbers.js"
    try fs.unlinkSync "#{fixturePath}/literate/letters.js"

  it 'should compile a .litcoffee input file', ->

    coffeebar "#{fixturePath}/literate/numbers.litcoffee"

    testFile = fs.readFileSync "#{fixturePath}/literate/numbers.js", 'utf8'
    controlFile = fs.readFileSync "#{fixturePath}/control/litnumbers.js", 'utf8'
    
    assert testFile.length
    assert.equal testFile, controlFile

   it 'should compile a .coffee.md input file', ->

    coffeebar "#{fixturePath}/literate/letters.coffee.md"

    testFile = fs.readFileSync "#{fixturePath}/literate/letters.js", 'utf8'
    controlFile = fs.readFileSync "#{fixturePath}/control/litletters.js", 'utf8'
    
    assert testFile.length
    assert.equal testFile, controlFile

  after ->
    try fs.unlinkSync "#{fixturePath}/literate/numbers.js"
    try fs.unlinkSync "#{fixturePath}/literate/letters.js"