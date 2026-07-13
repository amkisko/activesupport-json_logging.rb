require "fileutils"
require "open3"
require "active_support/core_ext/object/blank"

module BenchmarkProfile
  module_function

  def reset!
    @lines = []
  end

  def log(message = "")
    line = message.to_s
    @lines ||= []
    @lines << line
    $stdout.puts(line) unless line.empty?
    line
  end

  def write!(repository_root: default_repository_root)
    lines = @lines
    return if lines.blank?

    path = output_path(repository_root: repository_root)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, profile_header(repository_root: repository_root) + lines.join("\n") + "\n")
    $stdout.puts("\nBenchmark profile written to #{path}")
    path
  end

  def output_path(repository_root: default_repository_root, commit_sha: nil, working_tree_clean: nil, timestamp: nil)
    commit_identifier = commit_sha || self.commit_sha(repository_root: repository_root)
    clean_tree = working_tree_clean.nil? ? working_tree_clean?(repository_root: repository_root) : working_tree_clean
    filename = if clean_tree
      "profile_#{commit_identifier}.log"
    else
      recorded_at = timestamp || self.timestamp
      "profile_#{commit_identifier}_#{recorded_at}.log"
    end

    File.join(repository_root, "tmp", "benchmarks", filename)
  end

  def profile_header(repository_root: default_repository_root)
    [
      "# Benchmark profile",
      "# commit: #{commit_sha(repository_root: repository_root)}",
      "# recorded_at: #{Time.now.utc.iso8601}",
      "# working_tree_clean: #{working_tree_clean?(repository_root: repository_root)}",
      "# ruby: #{RUBY_VERSION}",
      ""
    ].join("\n")
  end

  def commit_sha(repository_root: default_repository_root)
    git_command("git rev-parse HEAD", repository_root: repository_root) || "unknown"
  end

  def working_tree_clean?(repository_root: default_repository_root)
    git_command("git status --porcelain", repository_root: repository_root).to_s.empty?
  end

  def timestamp
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def git_command(command, repository_root:)
    stdout, status = Open3.capture2(command, chdir: repository_root)
    return nil unless status.success?

    stdout.strip
  rescue
    nil
  end

  def default_repository_root
    File.expand_path("../..", __dir__)
  end
end
