# Written by Zeke Stephens on March 25, 2026
# All contributions are dedicated to the public domain by the terms of CC0 1.0
# A copy of the license is included alongside this source code
class Luahbtex < Formula
  desc "Extended version of pdfTeX using Lua as an embedded scripting language"
  homepage "https://www.luatex.org"
  url "https://gitlab.lisn.upsaclay.fr/texlive/luatex/-/archive/1.24.0-TeXLive-2026/luatex-1.24.0-TeXLive-2026.tar.gz"
  version "1.24.0"
  sha256 "92374b32e52e22e0dfcad9e212126d51480e679bce83e5e3173c8978bd0d1ad8"
  license "GPL-2.0-or-later"
  depends_on "pkgconf" => :build
  depends_on "graphite2"
  depends_on "harfbuzz"
  depends_on "libpng"
  depends_on "libzzip"
  uses_from_macos "zlib"

  def install
    args = %w[
      --disable-all-pkgs
      --disable-shared
      --enable-largefile
      --enable-web2c
      --enable-luatex
      --enable-luahbtex
      --disable-tex
      --disable-etex
      --disable-ptex
      --disable-eptex
      --disable-uptex
      --disable-euptex
      --disable-aleph
      --disable-hitex
      --disable-pdftex
      --disable-mp
      --disable-pmp
      --disable-upmp
      --disable-xetex
      --disable-mf
      --disable-mflua
      --disable-mfluajit
      --disable-luajittex
      --disable-luajithbtex
      --disable-texprof
      --disable-ipc
      --disable-dump-share
      --disable-native-texlive-build
      --without-system-ptexenc
      --without-system-kpathsea
      --without-system-pplib
      --with-system-zlib
      --with-system-libpng
      --with-system-harfbuzz
      --with-system-graphite2
      --with-system-zziplib
      --without-mf-x-toolkit
      --without-x
    ]

    rm_r "source/libs/harfbuzz"
    rm_r "source/libs/graphite2"
    rm_r "source/libs/zlib"
    rm_r "source/libs/libpng"
    rm_r "source/libs/zziplib"
    rm_r "source/libs/luajit"
    rm_r "manual"
    rm_r "extrabin"

    mkdir "build" do
      system "../source/configure", *args
      system "make", "recurse"
      system "make", "-C", "libs"
      system "make", "-C", "texk", "MAKE_SUBDIRS="
      system "make", "-C", "texk/web2c", "luahbtex"
    end
    bin.install "build/texk/web2c/luahbtex"

    man_page = "source/texk/web2c/man/luatex.man"
    inreplace man_page, "@VERSION@", version.to_s
    man1.install man_page => "luahbtex.1"
  end

  test do
    system bin/"luahbtex", "--credits"
  end
end
