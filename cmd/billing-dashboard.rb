#!/usr/bin/env ruby
#
# billing-dashboard - Billing Intelligence Dashboard CLI
#
# Usage:
#   billing-dashboard run        # Run analytics pipeline
#   billing-dashboard serve      # Start dashboard server
#   billing-dashboard generate   # Generate TASKS.md
#   billing-dashboard test       # Run E2E tests
#   billing-dashboard version    # Show version
#

require 'fileutils'

HOMEBREW_PREFIX = ENV['HOMEBREW_PREFIX'] || '/opt/homebrew'
PACKAGE_DIR = "#{HOMEBREW_PREFIX}/opt/billing-dashboard"
LIBEXEC = "#{PACKAGE_DIR}/libexec"

def run_analytics
  puts "Running billing analytics pipeline..."
  system("#{LIBEXEC}/analysis/run.sh") || exit(1)
  puts "\n✓ Analytics complete. Outputs in #{LIBEXEC}/analysis/out/"
end

def serve_dashboard(port = 8000)
  puts "Starting dashboard server on http://localhost:#{port}/dashboard/"
  puts "Press Ctrl+C to stop."
  Dir.chdir("#{LIBEXEC}/dashboard") do
    exec("python3", "-m", "http.server", port.to_s)
  end
end

def generate_tasks
  puts "Generating TASKS.md from tasks.yaml..."
  system("#{LIBEXEC}/scripts/generate_tasks.py") || exit(1)
end

def run_tests
  puts "Running E2E tests..."
  Dir.chdir(LIBEXEC) do
    system("npm", "run", "test:e2e") || exit(1)
  end
end

def show_version
  version_file = "#{LIBEXEC}/VERSION"
  if File.exist?(version_file)
    puts "billing-dashboard #{File.read(version_file).strip}"
  else
    puts "billing-dashboard (development)"
  end
end

def show_help
  puts <<~HELP
    billing-dashboard - Billing Intelligence Dashboard CLI

    Usage:
      billing-dashboard <command> [options]

    Commands:
      run        Run analytics pipeline (bash analysis/run.sh)
      serve      Start dashboard server (default port 8000)
      generate   Generate TASKS.md from tasks.yaml
      test       Run E2E test suite
      version    Show version
      help       Show this help message

    Examples:
      billing-dashboard run
      billing-dashboard serve --port 3000
      billing-dashboard generate

    Documentation:
      https://github.com/joshuascottpaul/billing-dashboard-project
  HELP
end

# Parse arguments
command = ARGV[0] || 'help'

case command
when 'run'
  run_analytics
when 'serve'
  port = ARGV[1] || 8000
  serve_dashboard(port)
when 'generate'
  generate_tasks
when 'test'
  run_tests
when 'version', '-v', '--version'
  show_version
when 'help', '-h', '--help'
  show_help
else
  puts "Unknown command: #{command}"
  puts "Run 'billing-dashboard help' for usage."
  exit(1)
end
