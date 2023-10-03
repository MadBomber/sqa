# sqa/lib/patches/rover-data_frame.rb

# This Patch normalizes the keys to be class Symbol
# underscore.  It then uses these normalized keys to
# create accessor methods to the vectors in the data frame.

class Rover::DataFrame
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)

    normalize_keys unless keys.all?{|k| k.is_a?(Symbol)}
    create_accessor_methods
  end

  private

  def normalize_keys
  	mapping = {} # old_key: new_key

  	return if keys.empty?

  	keys.each do |key|
      next if is_date?(key)
  	  mapping[key] = underscore_key(sanitize_key(key))
  	end

  	rename(mapping)
  end


  def underscore_key(key)
    key.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase.to_sym
  end


  def sanitize_key(key)
    key.tr('.():/','').gsub(/^\d+.?\s/, "").tr(' ','_')
  end


  def is_date?(key)
    !/(\d{4}-\d{2}-\d{2})/.match(key.to_s).nil?
  end


  # NOTE: each key must be a Symbol
  def create_accessor_methods
  	return if keys.empty?

  	keys.each do |key|
  	  define_singleton_method(key) do
    	  self[key]
    	end
    end
  end
end
