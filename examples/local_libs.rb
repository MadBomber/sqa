# frozen_string_literal: true
#
# Ensure the example demo apps load the LOCAL sibling gem checkouts rather than
# any installed/published versions of the SQA libraries.
#
# Require this from every example BEFORE `require 'sqa'`:
#
#   require_relative 'local_libs'
#   require 'sqa'
#
# It prepends each local sibling gem's lib directory to $LOAD_PATH (when the
# checkout exists), so `require 'sqa'` and `require 'sqa/tai'` resolve to the
# working copies in this workspace instead of the installed gems.

# gem name => path to its lib/ directory, relative to this file (examples/).
LOCAL_SQA_LIBS = {
  'sqa'     => File.expand_path('../lib', __dir__),
  'sqa-tai' => File.expand_path('../../sqa-tai/lib', __dir__)
}.freeze

LOCAL_SQA_LIBS.each_value do |lib_path|
  $LOAD_PATH.unshift(lib_path) if File.directory?(lib_path) && !$LOAD_PATH.include?(lib_path)
end
