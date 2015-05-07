(function() {
  var YamlLoader, _, extend, fs, ursa, yaml;

  ursa = require('ursa');

  fs = require('fs');

  yaml = require('js-yaml');

  _ = require('lodash');

  extend = require('node.extend');

  YamlLoader = (function() {
    function YamlLoader(path1, options1) {
      this.path = path1;
      this.options = options1;
      if (this.path == null) {
        throw new Error('Missing path parameter.');
      }
      if (this.options.key != null) {
        this.key_file = ursa.createPrivateKey(fs.readFileSync(this.options.key));
      }
      this.env = this.options.env || process.env.NODE_ENV || 'development';
    }

    YamlLoader.prototype.load = function() {
      var configs, data, defaults, env;
      data = yaml.safeLoad(fs.readFileSync(this.path, 'utf8'));
      defaults = data["default"] || {};
      env = data[this.env] || {};
      configs = extend(true, extend(true, {}, defaults), env);
      return this.configs = this.parse(configs);
    };

    YamlLoader.prototype.parse = function(obj) {
      var _this, matches;
      _this = this;
      if (_.isArray(obj)) {
        return _.map(obj, function(value) {
          return _this.parse(value);
        });
      } else if (_.isObject(obj)) {
        _.each(obj, function(value, key) {
          return obj[key] = _this.parse(value);
        });
        return obj;
      } else {
        if (_.isString(obj) && /decrypt\(.+\)/.exec(obj)) {
          matches = /decrypt\((.+)\)/.exec(obj);
          return this.key_file.decrypt(matches[1], 'base64', 'utf8');
        } else {
          return obj;
        }
      }
    };

    return YamlLoader;

  })();

  module.exports = {
    load: function(path, env, options) {
      var loader;
      if (options == null) {
        options = {};
      }
      if (env != null) {
        if (_.isString(env)) {
          options.env = env;
        } else {
          options = env;
        }
      }
      loader = new YamlLoader(path, options);
      return loader.load();
    },
    encrypt: function(phrase, public_key) {
      var crt;
      crt = ursa.createPublicKey(fs.readFileSync(public_key));
      return crt.encrypt(phrase, 'utf8', 'base64');
    }
  };

}).call(this);
