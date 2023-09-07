# sqa/test/config_cli_override.rb
#
# This file is executed by config_test.rb
# with the envar SQA_DATA_DIR set to xyzzy
# That test procedure captures the STDOUT and
# asserts that this file returns "xyzzy" to
# STDOUT.
#
# What this shows is that the cli options will
# override both the default and the envar
#
# ASSYME: if it works for one config element
#         it will work for all config elements.

require_relative  'test_helper'
require 					"sqa/cli"

SQA.init "--data-dir magic"
STDOUT.print SQA.config.data_dir
