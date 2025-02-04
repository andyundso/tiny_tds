require "test_helper"
require "tiny_tds/gem"

class GemTest < Minitest::Spec
  gem_root ||= File.expand_path "../..", __FILE__

  describe TinyTds::Gem do
    # We're going to muck with some system globals so lets make sure
    # they get set back later
    original_platform = RbConfig::CONFIG["arch"]
    original_pwd = Dir.pwd

    after do
      RbConfig::CONFIG["arch"] = original_platform
      Dir.chdir original_pwd
    end

    describe "#root_path" do
      let(:root_path) { TinyTds::Gem.root_path }

      it "should be the root path" do
        _(root_path).must_equal gem_root
      end

      it "should be the root path no matter the cwd" do
        Dir.chdir "/"

        _(root_path).must_equal gem_root
      end
    end

    describe "#ports_root_path" do
      let(:ports_root_path) { TinyTds::Gem.ports_root_path }

      it "should be the ports path" do
        _(ports_root_path).must_equal File.join(gem_root, "ports")
      end

      it "should be the ports path no matter the cwd" do
        Dir.chdir "/"

        _(ports_root_path).must_equal File.join(gem_root, "ports")
      end
    end

    describe "#ports_bin_paths" do
      let(:ports_bin_paths) { TinyTds::Gem.ports_bin_paths }

      describe "when the ports directories exist" do
        let(:fake_bin_paths) do
          ports_host_root = File.join(gem_root, "ports", "fake-host-with-dirs")
          [
            File.join("a", "bin"),
            File.join("a", "inner", "bin"),
            File.join("b", "bin")
          ].map do |p|
            File.join(ports_host_root, p)
          end
        end

        before do
          RbConfig::CONFIG["arch"] = "fake-host-with-dirs"
          fake_bin_paths.each do |path|
            FileUtils.mkdir_p(path)
          end
        end

        after do
          FileUtils.remove_entry_secure(
            File.join(gem_root, "ports", "fake-host-with-dirs"), true
          )
        end

        it "should return all the bin directories" do
          _(ports_bin_paths.sort).must_equal fake_bin_paths.sort
        end

        it "should return all the bin directories regardless of cwd" do
          Dir.chdir "/"
          _(ports_bin_paths.sort).must_equal fake_bin_paths.sort
        end
      end

      describe "when the ports directories are missing" do
        before do
          RbConfig::CONFIG["arch"] = "fake-host-without-dirs"
        end

        it "should return no directories" do
          _(ports_bin_paths).must_be_empty
        end

        it "should return no directories regardless of cwd" do
          Dir.chdir "/"
          _(ports_bin_paths).must_be_empty
        end
      end
    end
  end
end
