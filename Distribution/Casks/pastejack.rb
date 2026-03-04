cask "pastejack" do
  version "0.8.1"
  sha256 "52fc5672305e299e4ce174f27a35b0be42cd5e1e8958d015ead14188a3219bd3"

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
