class BillingDashboard < Formula
  desc "Billing Intelligence Dashboard - Analytics and Executive Dashboard"
  homepage "https://github.com/joshuascottpaul/billing-dashboard-project"
  url "https://github.com/joshuascottpaul/billing-dashboard-project/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "a9e730c0a10310045077a88d06f02dc2e38cda6fe0058004c8433307fedd3e13"
  license "MIT"

  depends_on "python@3.14"
  depends_on "node"
  depends_on "duckdb"

  def install
    # Install libexec
    libexec.install Dir["*"]

    # Install CLI wrapper
    bin.install libexec/"cmd/billing-dashboard.rb" => "billing-dashboard"

    # Create version file
    (libexec/"VERSION").write("#{version}\n")

    # Install Python dependencies
    system "#{Formula["python@3.14"].opt_bin}/python3.14", "-m", "pip", "install", "-t", libexec/"venv/lib/python3.14/site-packages", "duckdb", "pandas", "openpyxl", "pyyaml"
  end

  def post_install
    # Install Playwright browsers
    system "npm", "install", "--prefix", libexec
    system "npx", "playwright", "install", "--with-deps", "chromium", chdir: libexec
  end

  test do
    # Test CLI version command
    assert_match "billing-dashboard", shell_output("#{bin}/billing-dashboard version")

    # Test CLI help command
    assert_match "Usage:", shell_output("#{bin}/billing-dashboard help")

    # Test task generator
    system "#{bin}/billing-dashboard", "generate"
    assert_predicate testpath/"libexec/TASKS.md", :exist?
  end
end
