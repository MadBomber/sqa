#!/usr/bin/env ruby
# scripts/generate_api_docs.rb
#
# Generates markdown API documentation from YARD comments
# for integration with MkDocs Material theme

require 'yard'
require 'fileutils'

# Output directory for generated markdown
OUTPUT_DIR = 'docs/api-reference'

# Clean and create output directory
FileUtils.rm_rf(OUTPUT_DIR)
FileUtils.mkdir_p(OUTPUT_DIR)

# Parse the codebase with YARD
YARD::Registry.load!
YARD.parse('lib/**/*.rb')

# Helper to sanitize filenames
def sanitize_filename(name)
  name.gsub('::', '_').gsub(/[^\w\-]/, '_').downcase
end

# Helper to format method signature
def method_signature(method)
  params = method.parameters.map do |param|
    name, default = param
    default ? "#{name} = #{default}" : name.to_s
  end.join(', ')

  "#{method.name}(#{params})"
end

# Helper to format parameter list
def format_params(method)
  return "" if method.tags(:param).empty?

  lines = ["!!! info \"Parameters\"\n"]
  lines << "    | Name | Type | Description |"
  lines << "    |------|------|-------------|"
  method.tags(:param).each do |param|
    type_str = param.types ? param.types.join(', ') : "Any"
    description = param.text || ""
    lines << "    | `#{param.name}` | `#{type_str}` | #{description} |"
  end
  lines.join("\n") + "\n"
end

# Helper to format return value
def format_return(method)
  return_tag = method.tag(:return)
  return "" unless return_tag

  type_str = return_tag.types ? return_tag.types.join(', ') : "Object"
  description = return_tag.text || ""

  lines = ["!!! success \"Returns\"\n"]
  lines << "    **Type:** `#{type_str}`\n"
  lines << "    \n"
  lines << "    #{description}\n" unless description.empty?
  lines.join("\n")
end

# Helper to format examples
def format_examples(method)
  examples = method.tags(:example)
  return "" if examples.empty?

  lines = ["!!! example \"Usage Examples\"\n"]
  examples.each_with_index do |example, idx|
    lines << "    ```ruby"
    example.text.each_line do |line|
      lines << "    #{line.rstrip}"
    end
    lines << "    ```"
    lines << "    " if idx < examples.length - 1  # Add spacing between examples
  end
  lines.join("\n") + "\n"
end

# Generate markdown for a class or module
def generate_class_doc(code_object)
  filename = "#{sanitize_filename(code_object.path)}.md"
  filepath = File.join(OUTPUT_DIR, filename)

  File.open(filepath, 'w') do |f|
    # Title with icon
    type_icon = code_object.type == :class ? "📦" : "🔧"
    f.puts "# #{type_icon} #{code_object.path}"
    f.puts

    # Description in a note box
    if code_object.docstring && !code_object.docstring.empty?
      f.puts "!!! note \"Description\""
      code_object.docstring.to_s.each_line do |line|
        f.puts "    #{line.rstrip}"
      end
      f.puts
    end

    # Source info in an abstract box
    f.puts "!!! abstract \"Source Information\""
    f.puts "    **Defined in:** `#{code_object.file}:#{code_object.line}`"
    if code_object.type == :class && code_object.superclass
      f.puts "    "
      f.puts "    **Inherits from:** `#{code_object.superclass}`"
    end
    f.puts

    # Constants
    constants = code_object.constants(false) rescue []
    constants = [] unless constants.is_a?(Array)
    if constants.any?
      f.puts "## 🔢 Constants"
      f.puts
      constants.each do |const|
        f.puts "### `#{const.name}`"
        f.puts
        if const.docstring && !const.docstring.empty?
          f.puts "!!! info \"\""
          const.docstring.to_s.each_line do |line|
            f.puts "    #{line.rstrip}"
          end
          f.puts
        end
        if const.value
          f.puts "**Value:** `#{const.value}`"
          f.puts
        end
      end
    end

    # Class Methods
    class_methods = code_object.meths(scope: :class, visibility: [:public, :protected])
    if class_methods.any?
      f.puts "## 🏭 Class Methods"
      f.puts

      class_methods.each do |method|
        next if method.name.to_s.start_with?('_')

        f.puts "### `.#{method_signature(method)}`"
        f.puts

        if method.docstring && !method.docstring.empty?
          method.docstring.to_s.each_line do |line|
            f.puts line.rstrip
          end
          f.puts
        end

        f.puts format_params(method)
        f.puts format_return(method)
        f.puts format_examples(method)

        f.puts "??? info \"Source Location\""
        f.puts "    `#{method.file}:#{method.line}`"
        f.puts
        f.puts "---"
        f.puts
      end
    end

    # Instance Methods
    instance_methods = code_object.meths(scope: :instance, visibility: [:public, :protected])
    if instance_methods.any?
      f.puts "## 🔨 Instance Methods"
      f.puts

      instance_methods.each do |method|
        next if method.name.to_s.start_with?('_')

        f.puts "### `##{method_signature(method)}`"
        f.puts

        if method.docstring && !method.docstring.empty?
          method.docstring.to_s.each_line do |line|
            f.puts line.rstrip
          end
          f.puts
        end

        f.puts format_params(method)
        f.puts format_return(method)
        f.puts format_examples(method)

        f.puts "??? info \"Source Location\""
        f.puts "    `#{method.file}:#{method.line}`"
        f.puts
        f.puts "---"
        f.puts
      end
    end

    # Attributes
    begin
      all_attrs = code_object.attributes
      if all_attrs && !all_attrs.empty?
        f.puts "## 📝 Attributes"
        f.puts

        all_attrs.each do |scope, attrs|
          next unless attrs
          attrs.each do |name, rw|
            access_type = rw[:read] && rw[:write] ? 'read/write' : rw[:read] ? 'read-only' : 'write-only'
            access_badge = rw[:read] && rw[:write] ? '🔄' : rw[:read] ? '👁️' : '✍️'

            f.puts "### #{access_badge} `#{name}` <small>#{access_type}</small>"
            f.puts

            method = rw[:read] || rw[:write]
            if method && method.docstring && !method.docstring.empty?
              method.docstring.to_s.each_line do |line|
                f.puts line.rstrip
              end
              f.puts
            end
          end
        end
      end
    rescue => e
      # Skip attributes if there's an error
    end
  end

  filename
end

# Generate index page
def generate_index(classes_by_namespace)
  File.open(File.join(OUTPUT_DIR, 'index.md'), 'w') do |f|
    f.puts "# 📚 API Reference"
    f.puts
    f.puts "Complete API documentation for all SQA classes and modules."
    f.puts
    f.puts "!!! tip \"Auto-Generated Documentation\""
    f.puts "    This documentation is automatically generated from YARD comments in the source code."
    f.puts "    Last updated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    f.puts

    classes_by_namespace.each do |namespace, objects|
      # Add icon based on namespace
      namespace_icon = namespace == "SQA" ? "🎯" : namespace.include?("Strategy") ? "📊" : "📦"
      f.puts "## #{namespace_icon} #{namespace}"
      f.puts

      objects.sort_by(&:name).each do |obj|
        type_icon = obj.type == :class ? "📦" : "🔧"
        type_text = obj.type == :class ? "Class" : "Module"
        filename = "#{sanitize_filename(obj.path)}.md"

        f.puts "### [#{type_icon} **#{obj.name}**](#{filename})"
        f.puts

        # Add brief description if available
        if obj.docstring && !obj.docstring.empty?
          brief = obj.docstring.split("\n").first
          if brief && brief.length < 120
            f.puts "!!! abstract \"\""
            f.puts "    #{brief}"
            f.puts
          end
        end
      end
      f.puts
    end
  end
end

# Main execution
puts "Generating markdown API documentation..."

# Get all classes and modules
classes_and_modules = YARD::Registry.all(:class, :module).reject { |obj| obj.path.start_with?('YARD') }

# Group by namespace
classes_by_namespace = classes_and_modules.group_by do |obj|
  parts = obj.path.split('::')
  parts.length == 1 ? "Top Level" : parts[0..-2].join('::')
end

# Generate documentation for each class/module
generated_files = []
classes_and_modules.each do |code_object|
  puts "  Generating #{code_object.path}..."
  filename = generate_class_doc(code_object)
  generated_files << filename
end

# Generate index
puts "  Generating index..."
generate_index(classes_by_namespace)

puts "\nGenerated #{generated_files.length} markdown files in #{OUTPUT_DIR}/"
puts "These files will be rendered by MkDocs with the Material theme."
