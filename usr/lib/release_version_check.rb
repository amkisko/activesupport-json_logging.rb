# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ReleaseVersionCheck
  YELLOW = "\033[1;33m"
  NC = "\033[0m"

  module_function

  def warn_if_already_released(version:, package_name:, registry: :rubygems)
    warnings = []
    existing_tags = existing_git_tags(version)
    warnings << "git tag exists (#{existing_tags.join(", ")})" unless existing_tags.empty?
    warnings << "#{registry_label(registry)} has version #{version}" if registry_version_exists?(version, package_name, registry)

    return if warnings.empty?

    puts "#{YELLOW}Warning: version #{version} may already be released (#{warnings.join("; ")}).#{NC}"
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
  rescue StandardError
    nil
  end
end
