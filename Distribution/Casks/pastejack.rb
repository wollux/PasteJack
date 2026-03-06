cask "pastejack" do
  version "0.9.6"
  sha256 "0d26bebcc0d079410228bea5e539565505d1c754faf33b1539043ec858591fde"

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
