# Base to contain common style guide logic
module StyleGuide
  CONFIG_DIR = "config/style_guides"

  class Base
    pattr_initialize :repo_config

    def violations_in_file(file)
      violations = FileViolations.new(file.filename)

      if repo_config.enabled_for?(name)
        violation_messages(file).each do |line_message|
          line = file.modified_line_at(line_message.line_number)
          if line
            violations.add(line, line_message.message)
          end
        end
      end

      violations.to_a
    end

    private

    def violation_messages(file)
      raise NotImplementedError.new("must implement ##{__method__}")
    end

    def name
      self.class.name.demodulize.underscore
    end
  end
end
