# test/yf_fetch_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

# bin/sqa-yf-fetch requires ferrum, which is deliberately not a dependency of
# the gem. Nothing touches Ferrum until a browser is launched, so an empty
# stand-in at the end of the load path (a real install still wins) is enough
# to load the script and test its pure methods. The CLI itself is guarded by
# $PROGRAM_NAME == __FILE__.
Dir.mktmpdir('ferrum-stub') do |stub_dir|
  File.write(File.join(stub_dir, 'ferrum.rb'), "module Ferrum; end\n")
  $LOAD_PATH.push(stub_dir)
  load File.expand_path('../bin/sqa-yf-fetch', __dir__)
ensure
  $LOAD_PATH.delete(stub_dir)
end

class YfFetchTest < Minitest::Test
  def session(cookie:, crumb:)
    SQA::YahooSession.new.tap do |s|
      s.instance_variable_set(:@cookie, cookie)
      s.instance_variable_set(:@crumb, crumb)
    end
  end

  # Evaluates the --print-env output in a POSIX shell and reads both values back.
  def eval_in_shell(text)
    out, status = Open3.capture2('sh', '-c', %(#{text}\nprintf '%s\\0%s' "$YF_COOKIE" "$YF_CRUMB"))
    assert status.success?, "shell exited #{status.exitstatus}"
    out.split("\0", 2)
  end

  def test_to_shell_round_trips_values_through_eval
    [
      [%(A=1; B=a$(echo X)`echo Y`b "q" 'z' $HOME \\ end), %(c$HOME`x`"'!)],
      ['A=1; B=2', 'abc.DEF/123'],
      ["a\nb\tc", 'd']
    ].each do |cookie, crumb|
      assert_equal [cookie, crumb], eval_in_shell(session(cookie:, crumb:).to_shell)
    end
  end

  def test_progress_goes_to_stderr_when_printing_env
    assert_same $stderr, yf_progress_io(parse_yf_options(['--print-env']))
    assert_same $stdout, yf_progress_io(parse_yf_options(['AAPL']))
  end
end
