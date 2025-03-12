# renovate: datasource=repology depName=homebrew/libiconv versioning=loose
ICONV_VERSION = ENV["TINYTDS_ICONV_VERSION"] || "1.18"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

# renovate: datasource=repology depName=homebrew/openssl@3 versioning=loose
OPENSSL_VERSION = ENV["TINYTDS_OPENSSL_VERSION"] || "3.4.0"
OPENSSL_SOURCE_URI = "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

# renovate: datasource=repology depName=homebrew/freetds versioning=loose
FREETDS_VERSION = ENV["TINYTDS_FREETDS_VERSION"] || "1.4.26"
FREETDS_SOURCE_URI = "http://www.freetds.org/files/stable/freetds-#{FREETDS_VERSION}.tar.bz2"
