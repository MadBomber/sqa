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
    gsub('::', '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2').tr("- ", "_")
      .downcase
  end

  alias to_snakecase to_underscore
  alias snakecase    to_underscore
  alias snake_case   to_underscore
  alias underscore   to_underscore

  ##################################
  ## Convert camel_case to CamelCase
  def to_camelcase
    gsub(%r{/(.?)}) { "::" + ::Regexp.last_match(1).upcase }
      .gsub(/(^|_)(.)/) {   ::Regexp.last_match(2).upcase }
  end

  alias camelcase to_camelcase
  alias camelize  to_camelcase

  ##################################
  ## Convert "CamelCase" into CamelCase
  def to_constant
    names = split('::')
    names.shift if names.empty? || names.first.empty?

    names.reduce(Object, :const_get)
  end

  alias constantize to_constant
end
