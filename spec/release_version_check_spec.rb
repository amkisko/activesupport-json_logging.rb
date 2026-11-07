# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../usr/lib/release_version_check"

RSpec.describe ReleaseVersionCheck do
  describe ".confirmation_accepted?" do
    it "accepts an explicit yes or an interactive default", :aggregate_failures do
      expect(described_class.confirmation_accepted?("y\n")).to be(true)
      expect(described_class.confirmation_accepted?("Y\n")).to be(true)
      expect(described_class.confirmation_accepted?("\n")).to be(true)
    end

    it "rejects EOF and other answers", :aggregate_failures do
      expect(described_class.confirmation_accepted?(nil)).to be(false)
      expect(described_class.confirmation_accepted?("n\n")).to be(false)
    end
  end

  describe ".changelog_includes_version?" do
    it "accepts plain and Keep a Changelog headings", :aggregate_failures do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "CHANGELOG.md")
        File.write(path, <<~MD)
          # CHANGELOG
          ## 1.3.2 (2026-11-03)
          ## [1.3.1] - 2026-09-04
          ## 9.9.9 (Unreleased)
        MD

        expect(described_class.changelog_includes_version?("1.3.2", path: path)).to be(true)
        expect(described_class.changelog_includes_version?("1.3.1", path: path)).to be(true)
        expect(described_class.changelog_includes_version?("9.9.9", path: path)).to be(false)
        expect(described_class.changelog_includes_version?("0.0.1", path: path)).to be(false)
      end
    end
  end

  describe ".require_changelog_version!" do
    it "aborts when the changelog file is missing" do
      expect {
        described_class.require_changelog_version!(version: "1.3.2", path: "tmp/missing-changelog.md")
      }.to raise_error(SystemExit)
    end

    it "aborts when the version heading is absent" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "CHANGELOG.md")
        File.write(path, "# CHANGELOG\n## 1.0.0\n")

        expect {
          described_class.require_changelog_version!(version: "1.3.2", path: path)
        }.to raise_error(SystemExit)
      end
    end

    it "passes when the changelog heading is present" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "CHANGELOG.md")
        File.write(path, "# CHANGELOG\n## 1.3.2 (2026-11-03)\n")

        expect {
          described_class.require_changelog_version!(version: "1.3.2", path: path)
        }.not_to raise_error
      end
    end
  end
end
