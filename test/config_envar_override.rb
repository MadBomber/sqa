# sqa/test/config_envar_override.rb
#
# This file is executed by config_test.rb
# with the envar SQA_DATA_DIR set to xyzzy
# That test procedure captures the STDOUT and
# asserts that this file returns "xyzzy" to
# STDOUT.
#
# ASSYME: if it works for one config element
#         it will work for all config elements.

require_relative  'test_helper'

SQA.init
STDOUT.print SQA.config.data_dir
