assert    = require 'assert'
fs        = require 'fs'
path      = require 'path'
coffeebar = require '../lib/coffeebar'

fixturePath = path.join __dirname, 'fixtures'

files = [
  'numbers'
  'sub/letters'
  'sub/subsub/letters2'
]

controls = []

describe 'Compile', ->

  before ->
    for file in files
      try fs.unlinkSync "#{fixturePath}/compile/#{file}.js"
      try fs.unlinkSync "#{fixturePath}/compile/join.js"
      controls.push fs.readFileSync "#{fixturePath}/control/#{file}.js", 'utf8'

  it 'should compile a single CS file', ->

    coffeebar "#{fixturePath}/compile/#{files[0]}.coffee"
    testFile = fs.readFileSync "#{fixturePath}/compile/#{files[0]}.js", 'utf8'
    assert testFile.length
    assert.equal testFile, controls[0]

  it 'should compile a directory of CS files', ->

    coffeebar "#{fixturePath}/compile"

    for file, i in files
      testFile = fs.readFileSync "#{fixturePath}/compile/#{files[i]}.js", 'utf8'
      assert testFile.length
      assert.equal testFile, controls[i]

  it 'should compile and join a directory of CS files', ->

    coffeebar "#{fixturePath}/compile", {output: "#{fixturePath}/compile/join.js"}
    testFile = fs.readFileSync "#{fixturePath}/compile/join.js", 'utf8'
    joinControl = fs.readFileSync "#{fixturePath}/control/join.js", 'utf8'
  
    assert testFile.length
    assert.equal testFile, joinControl


  after ->
    for file in files
      try fs.unlinkSync "#{fixturePath}/compile/#{file}.js"
      try fs.unlinkSync "#{fixturePath}/compile/join.js"