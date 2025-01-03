# encoding: UTF-8
require 'date'
require 'bigdecimal'
require 'rational'

require 'tiny_tds/version'
require 'tiny_tds/error'
require 'tiny_tds/client'
require 'tiny_tds/result'
require 'tiny_tds/gem'

begin
  # load the precompiled extension file
  ruby_version = /(\d+\.\d+)/.match(::RUBY_VERSION)
  require_relative "tiny_tds/#{ruby_version}/tiny_tds"
rescue LoadError
  # fall back to the extension compiled upon installation.
  # use "require" instead of "require_relative" because non-native gems will place C extension files
  # in Gem::BasicSpecification#extension_dir after compilation (during normal installation), which
  # is in $LOAD_PATH but not necessarily relative to this file
  # (see https://github.com/sparklemotion/nokogiri/issues/2300 for more)
  require "tiny_tds/tiny_tds"
end
