require_relative "recipe"

module Ports
  class Openssl < Recipe
    def initialize(version)
      super("openssl", version)

      set_patches
    end

    def configure
      return if configured?

      md5_file = File.join(tmp_path, "configure.md5")
      digest = Digest::MD5.hexdigest(computed_options.to_s)
      File.write(md5_file, digest)

      # Windows doesn't recognize the shebang so always explicitly use sh
      execute("configure", "sh -c \"./Configure #{computed_options.join(" ")}\"")
    end

    def install
      unless installed?
        execute("install", %(#{make_cmd} install_sw install_ssldirs))
      end
    end

    private

    def configure_defaults
      opts = [
        "shared",
        target_arch,
        "--openssldir=#{path}"
      ]

      if cross_build?
        opts << "--cross-compile-prefix=#{host}-"
      end

      opts
    end

    def target_arch
      if windows?
        arch = ""
        arch = "64" if /x86_64/.match?(host)

        "mingw#{arch}"
      else
        arch = "x32"
        arch = "x86_64" if /x86_64/.match?(host)

        "linux-#{arch}"
      end
    end

    def set_patches
      patch_files.concat get_patches(name, version)
    end
  end
end
