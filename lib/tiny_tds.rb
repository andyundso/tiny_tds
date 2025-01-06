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
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "tiny_tds/#{$1}/tiny_tds"
rescue LoadError
  require "tiny_tds/tiny_tds"
end
