# This formula installs the 'install-dependency' script from the scripts repository.
class InstallDependency < Formula
  # A short description of the script's purpose.
  desc "Installs a required dependency for other scripts"

  # The homepage for the scripts project.
  homepage "https://github.com/jmerhar/scripts"

  # The URL to the compressed archive of your scripts from a GitHub release.
  # You need to create a release in your 'scripts' repository and update this URL.
  url "https://github.com/jmerhar/scripts/archive/v1.0.tar.gz"

  # The SHA-256 checksum of the archive file for security.
  # Run `curl -L <url> | shasum -a 256` in your terminal to get the correct checksum.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  # The `install` method is where you place the installation logic.
  def install
    # This line installs the script into Homebrew's binary directory.
    # It takes the file from the archive path (`system/install-dependency.sh`)
    # and renames it to `install-dependency` for the global PATH.
    bin.install "system/install-dependency.sh" => "install-dependency"
  end
end
