# lib/sqa/plugin_manager.rb

# This class gives plug-in commands a way
# to extend the SQA::Config class propertities.

module SQA
  class PluginManager
    @registered_properties = {}

    class << self
      attr_accessor :registered_properties

      # name (Symbol)

      def new_property(name, options = {})
        @registered_properties[name.to_sym] = options
      end
    end
  end
end
