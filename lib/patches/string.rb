# sqa/lib/patches/string.rb


#####################################################################
###
##  File:  string.rb
##  Desc:  Monkey to the String class.
#

class String

  ##################################
  ## Convert CamelCase to camel_case
  def to_underscore
    self.gsub(/::/, '/')
    		.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    		.gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("- ", "_")
    		.downcase
  end

  alias :to_snakecase :to_underscore
  alias :snakecase    :to_underscore
  alias :snake_case   :to_underscore
  alias :underscore   :to_underscore


  ##################################
  ## Convert camel_case to CamelCase
  def to_camelcase
    self.gsub(/\/(.?)/) { "::" + $1.upcase }
    		.gsub(/(^|_)(.)/) { $2.upcase }
  end

  alias :camelcase :to_camelcase
  alias :camelize  :to_camelcase


  ##################################
  ## Convert "CamelCase" into CamelCase
  def to_constant
    names = self.split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      if '1.9' == RUBY_VERSION[0,3]
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      else
        constant = constant.const_get(name) || constant.const_missing(name)
      end
    end
    constant
  end

  alias :constantize :to_constant
end


