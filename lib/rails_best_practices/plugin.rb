# frozen_string_literal: true

require "tmpdir"
require "json"

module Danger
  # A danger plugin to check your rails project through rails_best_practices.
  #
  # @example Check by rails_best_practices
  #
  #          rails_best_practices.check
  #
  # @see  edvakf/danger-rails_best_practices
  # @tags ruby, rails
  #
  class DangerRailsBestPractices < Plugin
    # Runs rails_best_practices and comment on P-R
    #
    # @param   [Array<String>] command_opts
    #          command line options to rails_best_practices command
    # @return  [void]
    def check(command_opts: [])
      files = files_to_lint
      return if files.empty?

      Dir.mktmpdir do |dir|
        output_file = File.join(dir, "output.json")

        command_opts.unshift "rails_best_practices"
        command_opts.unshift "bundle", "exec" if File.exist?("Gemfile")
        command_opts.push "--format", "json"
        command_opts.push "--output-file", output_file

        # FIXME: has problem when file name contains a comma
        command_opts.push "--only", files_to_lint.map { |f| Regexp.escape(f) }.join(",")

        ok = system(*command_opts)

        unless ok
          raise "Error executing rails_best_practices (error code: #{$?})"
        end

        output = JSON.parse(File.read(output_file))

        unless output.empty?
          output.each do |result|
            warn(result["message"], file: relative_path(result["filename"]), line: result["line_number"].to_i)
          end
        end
      end
    end

    private

    def files_to_lint
      git.modified_files + git.added_files
    end

    def relative_path(file)
      file.sub(Dir.pwd, "").sub("/", "") if file.start_with? Dir.pwd
    end
  end
end
