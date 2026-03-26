# Written by Zeke Stephens on March 25, 2026
# All contributions are dedicated to the public domain by the terms of CC0 1.0
# A copy of the license is included alongside this source code
class Optex < Formula
  desc "LuaTeX format with extended Plain TeX macros"
  homepage "https://petr.olsak.net/optex/"
  url "https://github.com/olsak/OpTeX/archive/refs/tags/v1.19.tar.gz"
  sha256 "f87bb8b3d98a9924786c3ae1b0f9f7bdda4524512ef60f5fa7ec8f9df0395017"
  license :public_domain

  depends_on "luahbtex"

  # hyphenation files
  resource "hyph-utf8" do
    url "https://mirrors.ctan.org/language/hyph-utf8.zip"
    sha256 "ef3c55f7921eb6c1cdbacac2815c005a010473aed4f0c757040eab126a969b6b"
  end

  # OpenType font loader
  resource "luaotfload" do
    url "https://github.com/latex3/luaotfload/releases/download/v3.29/luaotfload.tds.zip"
    sha256 "7c819a377aab5c4f10d24aabd4bf8f1023b82ee078458aa8ede6b3e618cb1521"
  end

  # Donald Knuth's Plain TeX
  resource "plain" do
    url "https://mirrors.ctan.org/macros/plain/base.zip"
    sha256 "e4e8ebad20cee00f2905d833e8ef4e8a221e22899178a5eeda87f55510fc97b7"
  end

  # math font?
  resource "rsfs" do
    url "https://mirrors.ctan.org/systems/texlive/tlnet/archive/rsfs.tar.xz"
    sha256 "1afec0c5e9711f652675e38b7cd7e88101c44aa0d0ff317ad6ac06f1d2cc7043"
  end

  # Dependencies of luaotfload
  resource "lualibs" do
    url "https://mirrors.ctan.org/install/macros/luatex/generic/lualibs.tds.zip"
    sha256 "49f28367ad39f643192f016ce89a47b11241ac78c20f76e8947807282423556e"
  end

  resource "unicode-data" do
    url "https://mirrors.ctan.org/install/macros/generic/unicode-data.tds.zip"
    sha256 "ade5e88e19998cf2744ea9310d95de1a6ed0ea6ffc27b274ee9231407945ba06"
  end

  resource "lua-uni-algos" do
    url "https://mirrors.ctan.org/macros/luatex/generic/lua-uni-algos.zip"
    sha256 "664c5eb615ec5f05678fdc5bc37483a8f6df5c9ec8b0e9adabbbfb8f42a92418"
  end

  def install
    texmf = share/"texmf"

    (texmf/"tex/optex").install "optex/base", "optex/pkg"

    resource("hyph-utf8").stage do
      (texmf/"tex/generic/hyph-utf8").install Dir["*"]
    end

    resource("luaotfload").stage do
      cp_r Dir["*"], texmf
    end

    resource("unicode-data").stage do
      cp_r Dir["*"], texmf
    end

    resource("plain").stage do
      (texmf/"tex/macros/plain/base").install Dir["*"]
    end

    resource("lualibs").stage do
      cp_r Dir["*"], texmf
    end

    resource("lua-uni-algos").stage do
      (texmf/"tex/luatex/lua-uni-algos").mkpath
      (texmf/"tex/luatex/lua-uni-algos").install Dir["*.lua"]
    end

    resource("rsfs").stage do
      cp_r Dir["*"], texmf
    end
    
    (texmf/"fonts/map/pdftex/updmap").mkpath

    master_map = ""
    good_maps = ["rsfs.map"]

    Dir[texmf/"**/*.map"].each do |map_file|
      if good_maps.include?(File.basename(map_file).to_s)
        master_map += File.read(map_file) + "\n"
      end
    end

    (texmf/"fonts/map/pdftex/updmap/pdftex.map").write master_map

    (texmf/"web2c").mkpath
    (texmf/"web2c/texmf.cnf").write <<~EOS
      TEXMF = #{texmf}
      TEXMFHOME = ~/texmf

      TEXINPUTS = .;$TEXMFHOME/tex//;$TEXMF/tex//
      LUAINPUTS = .;$TEXMFHOME/tex//;$TEXMF/tex//;$TEXMF/scripts//
      TEXFORMATS = .;$TEXMF/web2c//

      openin_any = a
      openout_any = p

      TEXMFVAR = $HOME/.optex/texmf-var
      TEXMFCACHE = $TEXMFVAR

      OSFONTDIR = /System/Library/Fonts//:/Library/Fonts//:~/Library/Fonts//
    EOS

    ENV["TEXMFCNF"] = "#{texmf}/web2c"

    system "#{Formula["luahbtex"].opt_bin}/luahbtex", "-ini", "\\let\\fontspreload=\\relax \\input optex.ini"

    (texmf/"web2c/luatex").mkpath
    (texmf/"web2c/luatex").install "optex.fmt"

    (bin/"optex").write <<~EOS
      #!/bin/bash
      export TEXMFCNF="#{texmf}/web2c"
      mkdir -p "$HOME/.optex/texmf-var"
      exec "#{Formula["luahbtex"].opt_bin}/luahbtex" -fmt=optex "$@"
    EOS

    chmod 0755, bin/"optex"

    man_page = "optex/doc/optex.1"
    man1.install man_page => "optex.1"
  end

  def caveats
    <<~EOS
      OpTeX requires Unicode fonts at runtime. Install Latin Modern with:
        brew install --cask font-latin-modern font-latin-modern-math
      Or use any system font with \\fontfam at the top of your document.
    EOS
  end

  test do
    (testpath/"hello.tex").write <<~EOS
        
      \\font{Helvetica}
      hello world
      \\bye
    EOS

    system bin/"optex", "hello.tex"
    assert_path_exists testpath/"hello.pdf"
  end
end
