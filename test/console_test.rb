# test/console_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

# bin/sqa-console ships as the gem's executable. On Ruby 4.0+ irb is a bundled
# gem, not a default one, so the console only starts when irb is declared.
class ConsoleTest < Minitest::Test
  CONSOLE = File.expand_path('../bin/sqa-console', __dir__)

  def test_console_starts_and_evaluates_input
    output, status = Open3.capture2e(
      { 'IRBRC' => File::NULL }, RbConfig.ruby, CONSOLE,
      stdin_data: "puts SQA::VERSION\n"
    )

    assert status.success?, output
    assert_includes output, SQA::VERSION.to_s
  end
end
