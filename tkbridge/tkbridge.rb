class Tkbridge < Formula
  desc "TKBridge Distributed Connection System Host"
  homepage "https://github.com/toolskit/tkbridge"
  url "https://github.com/toolskit/tkbridge/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  service do
    run [opt_bin/"tkbridge", "start"]
    keep_alive true
    log_path var/"log/tkbridge.log"
    error_log_path var/"log/tkbridge.log"
  end

  test do
    system "#{bin}/tkbridge", "help"
  end
end
