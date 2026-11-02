# Not in homebrew/core yet. To bump: version and sha256 for macos-aarch64 from
# https://releases.herdr.dev/core/latest.json (`brew livecheck` shows if one is due).
class HerdrCore < Formula
  desc "Terminal runtime for coding agents (hc)"
  homepage "https://herdr.dev/"
  url "https://releases.herdr.dev/core/0.1.16/herdr-core-macos-aarch64.tar.gz"
  sha256 "698d8f0c44f4e4b15fec174d52a39d57a014cfd71added44b53a0753b469d0fd"
  license "Apache-2.0"

  livecheck do
    url "https://releases.herdr.dev/core/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on arch: :arm64
  depends_on :macos

  def install
    # macOS kills this ad-hoc signed binary on first run if it stays quarantined.
    system "/usr/bin/xattr", "-c", "herdr-core"
    bin.install "herdr-core"
    bin.install_symlink "herdr-core" => "hc"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hc --version")
  end
end
