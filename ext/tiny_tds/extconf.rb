require 'mkmf'
require_relative 'extconsts'

if ENV['MAINTAINER_MODE']
	$stderr.puts "Maintainer mode enabled."
	$CFLAGS <<
		' -Wall' <<
		' -ggdb' <<
		' -DDEBUG' <<
		' -pedantic'
	$LDFLAGS <<
		' -ggdb'
end

if gem_platform=with_config("cross-build")
  require 'mini_portile2'

  openssl_platform = with_config("openssl-platform")
	toolchain = with_config("toolchain")

  class BuildRecipe < MiniPortile
    def initialize(name, version, files)
      super(name, version)
      self.files = files
      rootdir = File.expand_path('../../..', __FILE__)
      self.target = File.join(rootdir, "ports")
      self.patch_files = Dir[File.join("patches", self.name, self.version, "*.patch")].sort
    end

    # this will yield all ports into the same directory, making our path configuration for the linker easier
    def port_path
      "#{@target}/#{host}"
    end

    def tmp_path
      "tmp/#{host}/ports/#{@name}/#{@version}"
    end

    def cook_and_activate
      checkpoint = File.join(self.target, "#{self.name}-#{self.version}-#{RUBY_PLATFORM}.installed")
			
      unless File.exist?(checkpoint)
				self.cook
				FileUtils.touch checkpoint
			end
			
      self.activate
      self
    end
  end

  openssl_recipe = BuildRecipe.new("openssl", OPENSSL_VERSION, [OPENSSL_SOURCE_URI]).tap do |recipe|
    class << recipe  
      attr_accessor :openssl_platform
      
      def configure
        envs = []
        envs << "CFLAGS=-DDSO_WIN32 -DOPENSSL_THREADS" if RUBY_PLATFORM =~ /mingw|mswin/
        envs << "CFLAGS=-fPIC -DOPENSSL_THREADS" if RUBY_PLATFORM =~ /linux/
        execute('configure', ['env', *envs, "./Configure", openssl_platform, "threads", "-static", "CROSS_COMPILE=#{host}-", configure_prefix, "--libdir=lib"], altlog: "config.log")
      end
      
      def compile
        execute('compile', "#{make_cmd} build_libs")
      end
      
      def install
        execute('install', "#{make_cmd} install_dev")
      end
    end

    recipe.openssl_platform = openssl_platform
    recipe.host = toolchain
    recipe.cook_and_activate
  end

  libiconv_recipe = BuildRecipe.new("libiconv", ICONV_VERSION, [ICONV_SOURCE_URI]).tap do |recipe|
    recipe.configure_options << "CFLAGS=-fPIC" if RUBY_PLATFORM =~ /linux/
    recipe.host = toolchain

    recipe.cook_and_activate
  end

  freetds_recipe = BuildRecipe.new("freetds", FREETDS_VERSION, [FREETDS_SOURCE_URI]).tap do |recipe|
    # i am not 100% what is going on behind the scenes
    # it seems that FreeTDS build system prefers OPENSSL_CFLAGS and OPENSSL_LIBS
    # but the linker still relies on LIBS and CPPFLAGS
    # removing one or the other leads to build failures in any case of FreeTDS
    recipe.configure_options << "CFLAGS=-fPIC" if RUBY_PLATFORM =~ /linux/
    recipe.configure_options << "LDFLAGS=-L#{openssl_recipe.path}/lib"
		recipe.configure_options << "LIBS=-liconv -lssl -lcrypto #{"-lwsock32 -lgdi32 -lws2_32 -lcrypt32" if RUBY_PLATFORM =~ /mingw|mswin/}"
    recipe.configure_options << "CPPFLAGS=-I#{openssl_recipe.path}/include"

    recipe.configure_options << "OPENSSL_CFLAGS=-L#{openssl_recipe.path}/lib"
    recipe.configure_options << "OPENSSL_LIBS=-lssl -lcrypto #{"-lwsock32 -lgdi32 -lws2_32 -lcrypt32" if RUBY_PLATFORM =~ /mingw|mswin/}"

    recipe.configure_options << "--with-openssl=#{openssl_recipe.path}"
    recipe.configure_options << "--with-libiconv-prefix=#{libiconv_recipe.path}"
    recipe.configure_options << "--disable-odbc"
    recipe.configure_options << "--enable-sspi" if RUBY_PLATFORM =~ /mingw|mswin/

    recipe.host = toolchain
    recipe.cook_and_activate
  end

  ENV["LDFLAGS"] = "-Wl,-rpath -Wl,#{openssl_recipe.path}/lib"
  dir_config('freetds', "#{freetds_recipe.path}/include", "#{freetds_recipe.path}/lib")

  # here we check that all our libraries are now available to the compiler
  # by calling "find_library", mkmf will compile a small programm that check for the existence of the library
  # and will append it to "LIBS" environment variable when compiling tiny_tds itself
  # on one hand, this is a check for us that building all the ports worked as expected
  # but is also required that linking all the libraries to tiny_tds will work

  # order matters heavily here when linking the resulting tiny_tds.so
  # for example, libcrypto by OpenSSL needs to see libcrypt32 on Windows in order to have all references resolved
  # same for sybdb, which needs to see all OpenSSL and libiconv stuff to have all references resolved
  if RUBY_PLATFORM =~ /mingw|mswin/
    find_library("crypt32", nil)
    find_library("ws2_32", nil)
    find_library("gdi32", nil)
    find_library("wsock32", nil)
  end

  find_library("crypto", nil)
  find_library("ssl", nil)
  find_library("iconv", "libiconv_open")
  find_library('sybdb', 'dbanydatecrack')
else
  # Make sure to check the ports path for the configured host
  architecture = RbConfig::CONFIG['arch']

  project_dir = File.expand_path("../../..", __FILE__)
  freetds_ports_dir = File.join(project_dir, 'ports', architecture, 'freetds', FREETDS_VERSION)
  freetds_ports_dir = File.expand_path(freetds_ports_dir)
  
  # Add all the special path searching from the original tiny_tds build
  # order is important here! First in, first searched.
  DIRS = %w(
    /opt/local
    /usr/local
  )

  if RbConfig::CONFIG['host_os'] =~ /darwin/i
    # Ruby below 2.7 seems to label the host CPU on Apple Silicon as aarch64
    # 2.7 and above print is as ARM64
    target_host_cpu = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7') ? 'aarch64' : 'arm64'

    if RbConfig::CONFIG['host_cpu'] == target_host_cpu
      # Homebrew on Apple Silicon installs into /opt/hombrew
      # https://docs.brew.sh/Installation
      # On Intel Macs, it is /usr/local, so no changes necessary to DIRS
      DIRS.unshift("/opt/homebrew")
    end
  end

  if ENV["RI_DEVKIT"] && ENV["MINGW_PREFIX"] # RubyInstaller Support
    DIRS.unshift(File.join(ENV["RI_DEVKIT"], ENV["MINGW_PREFIX"]))
  end

  # Add the ports directory if it exists for local developer builds
  DIRS.unshift(freetds_ports_dir) if File.directory?(freetds_ports_dir)

  # Grab freetds environment variable for use by people on services like
  # Heroku who they can't easily use bundler config to set directories
  DIRS.unshift(ENV['FREETDS_DIR']) if ENV.has_key?('FREETDS_DIR')

  # Add the search paths for freetds configured above
  ldirs = DIRS.flat_map do |path|
    ldir = "#{path}/lib"
    [ldir, "#{ldir}/freetds"]
  end

  idirs = DIRS.flat_map do |path|
    idir = "#{path}/include"
    [idir, "#{idir}/freetds"]
  end

  puts "looking for freetds headers in the following directories:\n#{idirs.map{|a| " - #{a}\n"}.join}"
  puts "looking for freetds library in the following directories:\n#{ldirs.map{|a| " - #{a}\n"}.join}"
  dir_config('freetds', idirs, ldirs)

  unless find_library('sybdb', 'dbanydatecrack')
    abort "Failed! Do you have FreeTDS 1.0.0 or higher installed?"
  end
end

if /solaris/ =~ RUBY_PLATFORM
	append_cppflags( '-D__EXTENSIONS__' )
end

find_header('sybfront.h') or abort "Can't find the 'sybfront.h' header"
find_header('sybdb.h') or abort "Can't find the 'sybdb.h' header"

create_makefile("tiny_tds/tiny_tds")
