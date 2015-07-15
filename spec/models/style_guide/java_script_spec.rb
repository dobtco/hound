require "rails_helper"

describe StyleGuide::JavaScript do
  include ConfigurationHelper

  describe "#file_review" do
    it "returns a completed file review" do
      repo_config = double("RepoConfig", enabled_for?: true, for: {})
      style_guide = StyleGuide::JavaScript.new(repo_config, "bob")
      commit_file = build_commit_file

      result = style_guide.file_review(commit_file)

      expect(result).to be_completed
    end

    context "with default config" do
      context "when semicolon is missing" do
        it "returns a collection of violation objects" do
          repo_config = double("RepoConfig", for: {})
          commit_file = build_commit_file("var foo = 'bar'")

          violations = violations_in(
            commit_file: commit_file,
            repo_config: repo_config
          )

          violation = violations.first
          expect(violation.filename).to eq commit_file.filename
          expect(violation.line_number).to eq 1
          expect(violation.messages).to match_array([
            "Missing semicolon.",
            "'foo' is defined but never used.",
          ])
        end
      end
    end

    context "when semicolon check is disabled in config" do
      context "when semicolon is missing" do
        it "returns no violation" do
          repo_config = double("RepoConfig", for: { "asi" => true })
          commit_file = build_commit_file("parseFloat('1')")

          violations = violations_in(
            commit_file: commit_file,
            repo_config: repo_config
          )

          expect(violations).to be_empty
        end
      end
    end

    context "when jshintrb returns nil violation" do
      it "returns no violations" do
        repo_config = double("RepoConfig", for: {})
        commit_file = double("CommitFile").as_null_object
        allow(Jshintrb).to receive_messages(lint: [nil])

        violations = violations_in(
          commit_file: commit_file,
          repo_config: repo_config
        )

        expect(violations).to be_empty
      end
    end

    context "when a global variable is ignored" do
      it "returns no violations" do
        repo_config = double("RepoConfig", for: { "predef" => ["myGlobal"] })
        commit_file = build_commit_file("$(myGlobal).hide();")

        violations = violations_in(
          commit_file: commit_file,
          repo_config: repo_config
        )

        expect(violations).to be_empty
      end
    end

    context "non-thoughtbot pull request" do
      it "uses the default hound configuration" do
        spy_on_file_read
        spy_on_jshintrb
        configuration_file_path = default_configuration_file(
          StyleGuide::JavaScript
        )
        repo_config = double("RepoConfig", for: {})
        commit_file = build_commit_file("$(myGlobal).hide();")

        violations_in(
          commit_file: commit_file,
          repo_config: repo_config,
          repository_owner_name: "not_thoughtbot"
        )

        expect(File).to have_received(:read).with(configuration_file_path)
        expect(Jshintrb).to have_received(:lint).
          with(anything, default_configuration)
      end
    end

    context "thoughtbot pull request" do
      it "uses the thoughtbot hound configuration" do
        spy_on_file_read
        spy_on_jshintrb
        commit_file = build_commit_file("$(myGlobal).hide();")
        configuration_file_path = thoughtbot_configuration_file(
          StyleGuide::JavaScript
        )
        repo_config = double("RepoConfig", for: {})

        violations_in(
          commit_file: commit_file,
          repo_config: repo_config,
          repository_owner_name: "thoughtbot"
        )

        expect(File).to have_received(:read).with(configuration_file_path)
        expect(Jshintrb).to have_received(:lint).
          with(anything, thoughtbot_configuration)
      end
    end

    context "with ES6 support enabled" do
      it "respects ES6" do
        repo_config = double("RepoConfig", for: { esnext: true })
        commit_file = build_commit_file("import Ember from 'ember'")

        violations = violations_in(
          commit_file: commit_file,
          repo_config: repo_config
        )

        violation = violations.first
        expect(violation.messages).to match_array([
          "Missing semicolon.",
          "'Ember' is defined but never used.",
        ])
      end
    end
  end

  describe "#file_included?" do
    context "file is in excluded file list" do
      it "returns false" do
        repo_config = double("RepoConfig", ignored_javascript_files: ["foo.js"])
        style_guide = StyleGuide::JavaScript.new(repo_config, "ralph")
        commit_file = double("CommitFile", filename: "foo.js")

        included = style_guide.file_included?(commit_file)

        expect(included).to be false
      end
    end

    context "file is not excluded" do
      it "returns true" do
        repo_config = double("RepoConfig", ignored_javascript_files: ["foo.js"])
        style_guide = StyleGuide::JavaScript.new(repo_config, "ralph")
        commit_file = double("CommitFile", filename: "bar.js")

        included = style_guide.file_included?(commit_file)

        expect(included).to be true
      end
    end

    it "matches a glob pattern" do
      repo_config = double(
        "RepoConfig",
        ignored_javascript_files: [
          "app/assets/javascripts/*.js",
          "vendor/*",
        ]
      )
      style_guide = StyleGuide::JavaScript.new(repo_config, "ralph")
      commit_file1 = double(
        "CommitFile",
        filename: "app/assets/javascripts/bar.js"
      )
      commit_file2 = double(
        "CommitFile",
        filename: "vendor/assets/javascripts/foo.js"
      )

      expect(style_guide.file_included?(commit_file1)).to be false
      expect(style_guide.file_included?(commit_file2)).to be false
    end
  end

  def build_commit_file(content = "foo")
    filename = "some-file.js"
    line = double("Line", number: 1, patch_position: 1, changed?: true)
    double("CommitFile", filename: filename, line_at: line, content: content)
  end

  def violations_in(
    commit_file:,
    repo_config:,
    repository_owner_name: "not_thoughtbot"
  )
    style_guide = StyleGuide::JavaScript.new(
      repo_config,
      repository_owner_name
    )
    style_guide.file_review(commit_file).violations
  end

  def default_configuration
    config_file_path = default_configuration_file(StyleGuide::JavaScript)
    config_file = File.read(config_file_path)
    JSON.parse(config_file)
  end

  def thoughtbot_configuration
    config_file_path = thoughtbot_configuration_file(StyleGuide::JavaScript)
    config_file = File.read(config_file_path)
    JSON.parse(config_file)
  end

  def spy_on_jshintrb
    allow(Jshintrb).to receive(:lint).and_return([])
  end
end
