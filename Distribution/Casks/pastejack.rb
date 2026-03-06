cask "pastejack" do
  version "0.9.0"
  sha256 "fe92d2acf11494fec56d0e1aa8a82424d20173634fd52474a010f8c02b65d7ea"

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
