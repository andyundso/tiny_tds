# encoding: utf-8
require 'test_helper'
require 'tiny_tds/gem'

class GemTest < Minitest::Spec
  gem_root ||= File.expand_path '../..', __FILE__

  describe TinyTds::Gem do
    describe '#root_path' do
      let(:root_path) { TinyTds::Gem.root_path }

      it 'should be the root path' do
        _(root_path).must_equal gem_root
      end

      it 'should be the root path no matter the cwd' do
        Dir.chdir '/'

        _(root_path).must_equal gem_root
      end
    end
  end
end
