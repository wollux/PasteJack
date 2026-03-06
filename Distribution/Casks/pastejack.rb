cask "pastejack" do
  version "0.9.7"
  sha256 "591be4a9182fb540b248a538773e3ebd8f2f4c4136bac24737cbbc1f9f6772d6"

  url "https://github.com/wollux/PasteJack/releases/download/v#{version}/PasteJack-#{version}.dmg"
  name "PasteJack"
  desc "Paste clipboard contents as simulated keystrokes — bypass paste-blocking"
  homepage "https://github.com/wollux/PasteJack"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "PasteJack.app"

  zap trash: [
    "~/Library/Preferences/com.pastejack.app.plist",
    "~/Library/Application Support/PasteJack",
  ]

  caveats <<~EOS
    PasteJack requires Accessibility permission to simulate keystrokes.

    After installation, go to:
      System Settings > Privacy & Security > Accessibility
    and enable PasteJack.

    Default hotkey: Ctrl+Shift+V
  EOS
end
