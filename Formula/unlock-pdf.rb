# This formula installs the 'unlock-pdf' script from the scripts repository.
class UnlockPdf < Formula
  # A short description of the script's purpose.
  desc "Unlocks a password-protected PDF"

  # The homepage for the scripts project.
  homepage "https://github.com/jmerhar/scripts"

  # The URL to the compressed archive of your scripts from a GitHub release.
  # You need to create a release in your 'scripts' repository and update this URL.
  url "https://github.com/jmerhar/scripts/archive/v1.0.tar.gz"

  # The SHA-256 checksum of the archive file for security.
  # Run `curl -L <url> | shasum -a 256` in your terminal to get the correct checksum.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  # This is the crucial line for dependencies. It tells Homebrew that this formula
  # requires the "install-dependency" formula to be installed first.
  depends_on "install-dependency"

  # The `install` method is where you place the installation logic.
  def install
    # This line installs the script into Homebrew's binary directory.
    # It takes the file from the archive path (`utility/unlock-pdf.sh`)
    # and renames it to `unlock-pdf` for the global PATH.
    bin.install "utility/unlock-pdf.sh" => "unlock-pdf"
  end
end
