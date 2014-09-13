# Determine CoffeeScript style guide violations per-line.
module StyleGuide
  class CoffeeScript < Base
    DEFAULT_CONFIG_FILE = File.join(CONFIG_DIR, "coffeescript.json")

    private

    def violation_messages(file)
      Coffeelint.lint(file.content, config).map do |violation|
        LineMessage.new(violation["lineNumber"], violation["message"])
      end
    end

    def config
      default_config.merge(repo_config.for(name))
    end

    def default_config
      JSON.parse(File.read(DEFAULT_CONFIG_FILE))
    end
  end
end
