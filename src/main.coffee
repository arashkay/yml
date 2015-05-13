ursa = require 'ursa'
fs = require 'fs'
yaml = require 'js-yaml'
_ = require 'lodash'
extend = require 'node.extend'

# ## Yaml Config Reader (with ENV and Securing values support)
#
class YamlLoader

  constructor: (@path, @options) ->
    throw new Error 'Missing path parameter.' unless @path?
    if @options.key?
      @key_file = ursa.createPrivateKey fs.readFileSync @options.key
    @env = @options.env || process.env.NODE_ENV || 'development'
  
  load: -> 
    data = yaml.safeLoad fs.readFileSync(@path, 'utf8')
    defaults = data.default || {}
    env = data[@env] || {}
    configs = extend true, extend(true, {}, defaults), env
    configs = data if _.isEmpty configs
    @configs = @parse configs

  parse: (obj) ->
    _this = @
    if _.isArray(obj)
      _.map obj, (value) -> _this.parse value
    else if _.isObject(obj)
      _.each obj, (value, key) -> obj[key] = _this.parse value
      obj 
    else
      if _.isString(obj) && /decrypt\(.+\)/.exec(obj)
        throw new Error 'Private key for decryption is missing...' unless @key_file?
        matches = /decrypt\((.+)\)/.exec(obj)
        @key_file.decrypt matches[1], 'base64', 'utf8'
      else
        obj 

module.exports = {
  
  load: (path, env, options={}) ->
    if env?
      (if _.isString env
        options.env = env
      else
        options = env)
    loader = new YamlLoader path, options
    loader.load()
  
  encrypt: (phrase, public_key) ->
    crt = ursa.createPublicKey fs.readFileSync public_key
    crt.encrypt phrase, 'utf8', 'base64'
}

