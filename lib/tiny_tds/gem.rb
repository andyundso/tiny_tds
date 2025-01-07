require 'rbconfig'

module TinyTds
  module Gem
    class << self
      def root_path
        File.expand_path '../../..', __FILE__
      end

      def exe_path
        File.join(root_path, "exe")
      end
    end
  end
end
