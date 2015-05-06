should = require('chai').should()
ursa = require 'ursa'
fs = require 'fs'
Yml = require '../build/main'

describe 'Yml', ->
  
  path = __dirname+'/config.yml'
  key  = __dirname+'/security.key.pem'
  cert = __dirname+'/security.pub'

  it "should load config and deep merge defaults with env", ->
    configs = Yml.load path, { key: key }
    configs.should.be.an 'object'
    configs.username.should.be.equal 'admin'
    configs.devices.should.be.eql { android: true, windows: true, ios: true }
    configs.password.should.be.equal 'password'
    configs.days.should.be.instanceof Array

  it "should load config based on env", ->
    configs = Yml.load path, 'production', { key: key }
    configs.password.should.be.equal 'secret'

  it "should salt strings", ->
    phrase = 'password'
    salt = Yml.encrypt phrase, cert
    @key_file = ursa.createPrivateKey fs.readFileSync key
    decrypted = @key_file.decrypt salt, 'base64', 'utf8'
    decrypted.should.be.equal phrase
