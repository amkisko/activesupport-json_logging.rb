require "fileutils"

module BenchmarkProfiler
  module_function

  def profile_cpu(label:, iterations:, repository_root: BenchmarkProfile.send(:default_repository_root), &block)
    require "stackprof"

    path = output_path(label: label, extension: "dump", repository_root: repository_root)
    FileUtils.mkdir_p(File.dirname(path))

    StackProf.run(mode: :cpu, out: path) do
      iterations.times(&block)
    end

    BenchmarkProfile.log("\nStackProf CPU profile written to #{path}")
    path
  end

  def profile_allocations(label:, iterations:, repository_root: BenchmarkProfile.send(:default_repository_root), &block)
    require "stackprof"

    path = output_path(label: label, extension: "dump", repository_root: repository_root)
    FileUtils.mkdir_p(File.dirname(path))

    StackProf.run(mode: :object, out: path) do
      iterations.times(&block)
    end

    BenchmarkProfile.log("\nStackProf allocation profile written to #{path}")
    path
  end

  def compare_ips(repository_root: BenchmarkProfile.send(:default_repository_root), &block)
    require "benchmark/ips"

    capture = StringIO.new
    original_stdout = $stdout
    $stdout = capture

    begin
      Benchmark.ips(&block)
    ensure
      $stdout = original_stdout
    end

    capture.string.each_line do |line|
      BenchmarkProfile.log(line.chomp)
    end

    path = output_path(label: "ips", extension: "log", repository_root: repository_root)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, capture.string)
    BenchmarkProfile.log("\nBenchmark-ips report written to #{path}")
    path
  end

  def output_path(label:, extension:, repository_root:)
    commit_identifier = BenchmarkProfile.commit_sha(repository_root: repository_root)
    recorded_at = BenchmarkProfile.timestamp
    filename = if BenchmarkProfile.working_tree_clean?(repository_root: repository_root)
      "#{label}_#{commit_identifier}.#{extension}"
    else
      "#{label}_#{commit_identifier}_#{recorded_at}.#{extension}"
    end

    File.join(repository_root, "tmp", "benchmarks", filename)
  end
end
