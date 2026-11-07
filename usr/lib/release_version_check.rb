# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ReleaseVersionCheck
  YELLOW = "\033[1;33m"
  RED = "\033[1;31m"
  NC = "\033[0m"

  module_function

  def confirmation_accepted?(input)
    return false unless input

    answer = input.chomp
    answer.empty? || answer.casecmp?("y")
  end

  def warn_if_already_released(version:, package_name:, registry: :rubygems)
    warnings = []
    existing_tags = existing_git_tags(version)
    warnings << "git tag exists (#{existing_tags.join(", ")})" unless existing_tags.empty?
    warnings << "#{registry_label(registry)} has version #{version}" if registry_version_exists?(version, package_name, registry)

    return if warnings.empty?

    puts "#{YELLOW}Warning: version #{version} may already be released (#{warnings.join("; ")}).#{NC}"
  end

  # Fail unless CHANGELOG.md has a release heading for this version.
  # Accepts Keep a Changelog and plain forms:
  #   ## 1.2.3
  #   ## 1.2.3 (2026-10-27)
  #   ## [1.2.3]
  #   ## [1.2.3] - 2026-10-27
  # Rejects Unreleased headings, including "## 1.2.3 (Unreleased)".
  def require_changelog_version!(version:, path: "CHANGELOG.md")
    unless File.file?(path)
      abort "#{RED}release requires #{path} with a ## #{version} heading#{NC}"
    end
    unless changelog_includes_version?(version, path: path)
      abort "#{RED}release requires #{path} to include a version heading for #{version} " \
            "(e.g. ## #{version} or ## [#{version}])#{NC}"
    end
  end

  def changelog_includes_version?(version, path: "CHANGELOG.md")
    return false unless File.file?(path)

    File.foreach(path) do |line|
      next if line.match?(/Unreleased/i)
      return true if changelog_line_has_version?(line, version)
    end
    false
  end

  def changelog_line_has_version?(line, version)
    return false if line.match?(/Unreleased/i)

    rest = line[/^\#\#\s+(.*)/, 1]
    return false unless rest

    rest = rest.strip
    if rest.start_with?("[")
      candidate = rest[/\A\[([^\]]+)\]/, 1]
      candidate == version
    else
      rest == version || rest.start_with?("#{version} ", "#{version}(")
    end
  end

  def existing_git_tags(version)
    [version, "v#{version}"].select do |tag|
      system("git", "rev-parse", "--verify", "refs/tags/#{tag}", out: File::NULL, err: File::NULL)
    end
  end

  def registry_version_exists?(version, package_name, registry)
    case registry
    when :rubygems then rubygems_version_exists?(version, package_name)
    when :hex then hex_version_exists?(version, package_name)
    when :crates_io then crates_io_version_exists?(version, package_name)
    else false
    end
  end

  def registry_label(registry)
    case registry
    when :rubygems then "RubyGems"
    when :hex then "Hex"
    when :crates_io then "crates.io"
    else registry.to_s
    end
  end

  def rubygems_version_exists?(version, gem_name)
    response = http_get("https://rubygems.org/api/v1/versions/#{gem_name}.json")
    return false unless response

    JSON.parse(response).any? { |entry| entry["number"] == version }
  rescue JSON::ParserError
    false
  end

  def hex_version_exists?(version, package_name)
    !http_get("https://hex.pm/api/packages/#{package_name}/releases/#{version}").nil?
  end

  def crates_io_version_exists?(version, crate_name)
    !http_get("https://crates.io/api/v1/crates/#{crate_name}/#{version}").nil?
  end

  def http_get(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "release-version-check"
      http.request(request)
    end

    response.body if response.is_a?(Net::HTTPSuccess)
  rescue
    nil
  end
end
