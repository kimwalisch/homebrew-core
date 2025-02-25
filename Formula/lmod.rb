class Lmod < Formula
  desc "Lua-based environment modules system to modify PATH variable"
  homepage "https://lmod.readthedocs.io"
  url "https://github.com/TACC/Lmod/archive/8.7.1.tar.gz"
  sha256 "7b271a6e8509174707154fee502ab18a059c3e3c9d4b37cbb3c930bdd5b75e37"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "f00b89e0dc6a01e7ebceff9de480dc5e01f1a91c6854d64128fb8698c2777fbb"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "5860251e9fa6cff3efe092cb3a731e2d95296842e469f42e0175f172e3b5e67b"
    sha256 cellar: :any_skip_relocation, monterey:       "25983d95bbcd6e1aa96611153118897ddd602ab17fa801bb51b33f1c82f746ab"
    sha256 cellar: :any_skip_relocation, big_sur:        "f526716f46508f484885cf12b443d1fba8392f0977d1a00be9777fce87faeaf8"
    sha256 cellar: :any_skip_relocation, catalina:       "52c19ff673524f4f23f6fcad782d358599dbc757c1a8393eebb1fd417c4e634c"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "e99dbf4a7b05f3173165be6c66c5d29d63293916e0dfac182559537438395f4a"
  end

  depends_on "luarocks" => :build
  depends_on "pkg-config" => :build
  depends_on "lua"

  uses_from_macos "tcl-tk"

  resource "luafilesystem" do
    url "https://github.com/keplerproject/luafilesystem/archive/v1_8_0.tar.gz"
    sha256 "16d17c788b8093f2047325343f5e9b74cccb1ea96001e45914a58bbae8932495"
  end

  resource "luaposix" do
    url "https://github.com/luaposix/luaposix/archive/refs/tags/v35.1.tar.gz"
    sha256 "1b5c48d2abd59de0738d1fc1e6204e44979ad2a1a26e8e22a2d6215dd502c797"
  end

  def install
    luaversion = Formula["lua"].version.major_minor
    luapath = libexec/"vendor"
    ENV["LUA_PATH"] = "?.lua;" \
                      "#{luapath}/share/lua/#{luaversion}/?.lua;" \
                      "#{luapath}/share/lua/#{luaversion}/?/init.lua"
    ENV["LUA_CPATH"] = "#{luapath}/lib/lua/#{luaversion}/?.so"

    resources.each do |r|
      r.stage do
        system "luarocks", "make", "--tree=#{luapath}"
      end
    end

    system "./configure", "--with-siteControlPrefix=yes", "--prefix=#{prefix}"
    system "make", "install"
  end

  def caveats
    <<~EOS
      To use Lmod, you should add the init script to the shell you are using.

      For example, the bash setup script is here: #{opt_prefix}/init/profile
      and you can source it in your bash setup or link to it.

      If you use fish, use #{opt_prefix}/init/fish, such as:
        ln -s #{opt_prefix}/init/fish ~/.config/fish/conf.d/00_lmod.fish
    EOS
  end

  test do
    sh_init = "#{prefix}/init/sh"

    (testpath/"lmodtest.sh").write <<~EOS
      #!/bin/sh
      . #{sh_init}
      module list
    EOS

    assert_match "No modules loaded", shell_output("sh #{testpath}/lmodtest.sh 2>&1")

    system sh_init
    output = shell_output("#{prefix}/libexec/spider #{prefix}/modulefiles/Core/")
    assert_match "lmod", output
    assert_match "settarg", output
  end
end
