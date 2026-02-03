cask "promptist" do
  version "0.0.4"
  sha256 "6217c3632a84acb74a0595c1c3a646010888a4d9cbf8f9acc1c465a0e94a30df"

  url "https://github.com/jadru/homebrew-promptist/releases/download/v#{version}/Promptist-#{version}.dmg"
  name "Promptist"
  desc "AI prompt template launcher for macOS"
  homepage "https://github.com/jadru/homebrew-promptist"

  depends_on macos: ">= :sequoia"

  app "Promptist.app"

  zap trash: [
    "~/Library/Preferences/com.jadru.promptist.plist",
    "~/Library/Application Support/Promptist",
  ]
end
