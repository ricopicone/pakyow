# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/indifferentize"
require "pakyow/support/safe_string"

require "string_doc"

module Pakyow
  module Presenter
    # Provides an interface for manipulating view templates.
    #
    class View
      class << self
        # Creates a view from a file.
        #
        def load(path, content: nil)
          new(content || File.read(path))
        end

        # Creates a view wrapping an object.
        #
        def from_object(delegate, object)
          allocate.tap do |instance|
            instance.instance_variable_set(:@delegate, delegate)
            instance.instance_variable_set(:@object, object)
            instance.instance_variable_set(:@info, {})
            instance.instance_variable_set(:@logical_path, nil)

            if object.respond_to?(:attributes)
              instance.attributes = object.attributes
            else
              instance.instance_variable_set(:@attributes, nil)
            end
          end
        end
      end

      include Support::SafeStringHelpers

      using Support::Indifferentize
      using Support::Refinements::Array::Ensurable

      extend Forwardable
      def_delegators :@object, :type, :label, :labeled?

      # @api private
      attr_reader :delegate, :object

      # @api private
      attr_writer :object

      # The logical path to the view template.
      #
      attr_reader :logical_path

      # Creates a view with +html+.
      #
      def initialize(html, info: {}, logical_path: nil)
        @delegate, @info, @logical_path = StringDoc.new(html), info, logical_path
        @object, @attributes = nil, nil
      end

      def initialize_copy(_)
        super

        @info = @info.dup
        @delegate = @delegate.dup

        if @object
          original = @object
          @object = @object.dup
          @delegate.node_did_mutate(original, @object)

          if @object.respond_to?(:attributes)
            self.attributes = @object.attributes
          else
            @attributes = nil
          end
        end
      end

      # Finds a view binding by name. When passed more than one value, the view will
      # be traversed through each name. Returns a {VersionedView}.
      #
      def find(*names, channel: nil)
        if names.any?
          named = names.shift.to_sym
          combined_channel = Array.ensure(channel).join(":")

          found = each_binding(named).each_with_object([]) do |node, acc|
            if !channel || node.label(:combined_channel) == combined_channel || node.label(:combined_channel).end_with?(":" + combined_channel)
              acc << View.from_object(@delegate, node)
            end
          end

          result = if names.empty? && !found.empty? # found everything; wrap it up
            VersionedView.new(found)
          elsif names.count > 0 # descend further
            found.first.find(*names, channel: channel)
          else
            nil
          end

          if result && block_given?
            yield result
          end

          result
        else
          nil
        end
      end

      # Finds all view bindings by name, returning an array of {View} objects.
      #
      def find_all(named)
        each_binding(named).map { |node|
          View.from_object(@delegate, node)
        }
      end

      # Finds a form with a binding matching +name+.
      #
      def form(name)
        @delegate.each_significant_node(:form, @object) do |form_node|
          return Form.from_object(@delegate, form_node) if form_node.label(:binding) == name
        end

        nil
      end

      # Returns all forms.
      #
      def forms
        @delegate.each_significant_node(:form, @object).map { |node|
          Form.from_object(@delegate, node)
        }
      end

      # Returns all components.
      #
      def components
        @delegate.each_significant_node_without_descending(:component, @object).map { |node|
          View.from_object(@delegate, node)
        }
      end

      # Returns all view info when +key+ is +nil+, otherwise returns the value for +key+.
      #
      def info(key = nil)
        if key.nil?
          @info
        else
          @info.fetch(key.to_s, nil)
        end
      end

      # Returns a view for the +<head>+ node.
      #
      def head
        if head_node = @delegate.find_first_significant_node(:head, @object)
          View.from_object(@delegate, head_node)
        else
          nil
        end
      end

      # Returns a view for the +<body>+ node.
      #
      def body
        if body_node = @delegate.find_first_significant_node(:body, @object)
          View.from_object(@delegate, body_node)
        else
          nil
        end
      end

      # Returns a view for the +<title>+ node.
      #
      def title
        if title_node = @delegate.find_first_significant_node(:title, @object)
          View.from_object(@delegate, title_node)
        else
          nil
        end
      end

      # Yields +self+.
      #
      def with
        tap do
          yield self
        end
      end

      # Transforms +self+ to match structure of +object+.
      #
      def transform(object)
        tap do
          if object.nil? || (object.respond_to?(:empty?) && object.empty?)
            remove
          else
            removals = []
            each_binding_prop(descend: false) do |binding|
              binding_name = if binding.significant?(:multipart_binding)
                binding.label(:binding_prop)
              else
                binding.label(:binding)
              end

              unless object.present?(binding_name)
                removals << binding
              end
            end

            removals.each do |removal|
              @delegate.remove_node(removal)
            end
          end

          yield self, object if block_given?
        end
      end

      # Binds a single object.
      #
      def bind(object)
        tap do
          unless object.nil?
            each_binding_prop do |binding|
              binding_name = if binding.significant?(:multipart_binding)
                binding.label(:binding_prop)
              else
                binding.label(:binding)
              end

              if object.include?(binding_name)
                value = if object.is_a?(Binder)
                  object.__content(binding_name, @delegate, binding)
                else
                  object[binding_name]
                end

                binding = bind_value_to_node(value, binding)
                binding = @delegate.set_node_label(binding, :used, true)
              end
            end

            # TODO: the next line is causing us to lose a reference or something...
            # so when we change attributes we replace @object, which is the correct thing to do...
            # attributes[:"data-id"] = object[:id]
            # @object = @delegate.set_node_label(@object, :used, true)
          end
        end
      end

      # Appends a view or string to +self+.
      #
      def append(view_or_string)
        tap do
          mutate_with_view_or_string(view_or_string, :append_to_node)
        end
      end

      # Prepends a view or string to +self+.
      #
      def prepend(view_or_string)
        tap do
          mutate_with_view_or_string(view_or_string, :prepend_to_node)
        end
      end

      # Inserts a view or string after +self+.
      #
      def after(view_or_string)
        tap do
          mutate_with_view_or_string(view_or_string, :insert_after_node)
        end
      end

      # Replaces +self+ with a view or string.
      #
      def replace(view_or_string)
        tap do
          mutate_with_view_or_string(view_or_string, :replace_node)
        end
      end

      # Removes +self+.
      #
      def remove
        tap do
          @delegate.remove_node(@object)
          @object = nil
        end
      end

      # Removes +self+'s children.
      #
      def clear
        tap do
          @delegate.remove_node_children(@object)
        end
      end

      # Safely sets the html value of +self+.
      #
      def html=(html)
        @object = @delegate.set_node_html(@object, ensure_html_safety(html.to_s))
      end

      # Returns true if +self+ is a binding.
      #
      def binding?
        @object.significant?(:binding)
      end

      # Returns true if +self+ is a container.
      #
      def container?
        @object.significant?(:container)
      end

      # Returns true if +self+ is a partial.
      #
      def partial?
        @object.significant?(:partial)
      end

      # Returns true if +self+ is a form.
      #
      def form?
        @object.significant?(:form)
      end

      # Returns true if +self+ equals +other+.
      #
      def ==(other)
        other.is_a?(self.class) && @delegate == other.delegate && @object == other.object
      end

      # Returns attributes object for +self+.
      #
      def attributes
        @attributes
      end
      alias attrs attributes

      # Wraps +attributes+ in a {Attributes} instance.
      #
      def attributes=(attributes)
        @attributes = Attributes.new(self, attributes)
      end
      alias attrs= attributes=

      # Returns the version name for +self+.
      #
      def version
        (label(:version) || VersionedView::DEFAULT_VERSION).to_sym
      end

      def html
        @delegate.node_html(@object)
      end

      def text
        @delegate.node_text(@object)
      end

      def render
        @delegate.render(node: @object)
      end
      alias to_s render
      alias to_xml render
      alias to_html render

      # @api private
      def binding_name
        label(:binding)
      end

      # @api private
      def channeled_binding_name
        [label(:binding)].concat(label(:channel)).join(":")
      end

      # @api private
      def each_binding_scope(descend: true)
        return enum_for(:each_binding_scope, descend: descend) unless block_given?

        method = if descend
          :each_significant_node
        else
          :each_significant_node_without_descending
        end

        @delegate.send(method, :binding, @object) do |node|
          if binding_scope?(node)
            yield node
          end
        end
      end

      # @api private
      def each_binding_prop(descend: true)
        return enum_for(:each_binding_prop, descend: descend) unless block_given?

        if @object.is_a?(StringDoc::Node) && @object.significant?(:multipart_binding)
          yield @object
        else
          method = if descend
            :each_significant_node
          else
            :each_significant_node_without_descending
          end

          @delegate.send(method, :binding, @object) do |node|
            if binding_prop?(node)
              yield node
            end
          end
        end
      end

      # @api private
      def each_binding(name)
        return enum_for(:each_binding, name) unless block_given?

        each_binding_scope do |node|
          yield node if node.label(:binding) == name
        end

        each_binding_prop do |node|
          yield node if node.label(:binding) == name
        end
      end

      # @api private
      def binding_scopes(descend: true)
        each_binding_scope(descend: descend).map(&:itself)
      end

      # @api private
      def binding_props(descend: true)
        each_binding_prop(descend: descend).map(&:itself)
      end

      # @api private
      def binding_scope?(node)
        node.significant?(:binding) && (node.significant?(:binding_within) || node.significant?(:multipart_binding) || node.label(:version) == :empty)
      end

      # @api private
      def binding_prop?(node)
        node.significant?(:binding) && (!node.significant?(:binding_within) || node.significant?(:multipart_binding))
      end

      # @api private
      def find_partials(partials, found = [])
        found.tap do
          @delegate.each_significant_node(:partial, @object) do |node|
            if replacement = partials[node.label(:partial)]
              found << node.label(:partial)
              replacement.find_partials(partials, found)
            end
          end
        end
      end

      # @api private
      def mixin(partials)
        tap do
          @delegate.each_significant_node(:partial, @object) do |partial_node|
            if replacement = partials[partial_node.label(:partial)]
              partial_node.replace(replacement.mixin(partials).object)
            end
          end
        end
      end

      # Thanks Dan! https://stackoverflow.com/a/30225093
      # @api private
      INFO_MERGER = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }

      # @api private
      def add_info(*infos)
        tap do
          infos.each do |info|
            @info.merge!(info, &INFO_MERGER)
          end
        end
      end

      private

      def mutate_with_view_or_string(view_or_string, mutation)
        @delegate.public_send(mutation, @object, view_from_view_or_string(view_or_string).delegate)
      end

      def bind_value_to_node(value, node)
        tag = node.tagname
        if StringDoc::Node.without_value?(tag)
          node
        else
          value = String(value)
          if StringDoc::Node.self_closing?(tag)
            if node.attributes[:value].nil?
              @delegate.set_node_attribute(node, :value, ensure_html_safety(value))
            else
              node
            end
          else
            @delegate.set_node_html(node, ensure_html_safety(value))
          end
        end
      end

      def view_from_view_or_string(view_or_string)
        if view_or_string.is_a?(View)
          view_or_string
        elsif view_or_string.is_a?(String)
          View.new(ensure_html_safety(view_or_string))
        else
          View.new(ensure_html_safety(view_or_string.to_s))
        end
      end
    end
  end
end
