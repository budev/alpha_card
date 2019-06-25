# frozen_string_literal: true

# typed: false
module AlphaCard
  # Attribute DSL for Alpha Card transaction variables
  module Attribute
    # Extends base class with Attributes DSL.
    #
    # @param base [Class] baseclass
    #
    # @example
    #   class User
    #     include AlphaCard::Attribute
    #   end
    #
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    # Attributes class methods
    #   * attribute
    #   * remove_attribute
    #   * attributes_set
    #
    module ClassMethods
      # Defines Attributes Set for the class.
      # Attributes set contains all the attributes names as key
      # and it's options as the value.
      #
      # @return [Hash] attributes set with options
      def attributes_set
        @attributes_set ||= {}
      end

      # Adds attribute to the class.
      # Defines reader and writer methods based on options hash.
      # Adds attribute to the global Attributes Set.
      #
      # @param name [Symbol, String] attribute name
      # @param options [Hash] attribute options
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :id, type: Integer, required: true, writable: false
      #     attribute :email, required: true, format: /.+@.+/
      #     attribute :name, type: String
      #     attribute :role, default: 'admin', values: ['admin', 'regular']
      #     attribute :status, types: [String, Symbol]
      #
      #     attribute :metadata, type: Hash
      #     attribute :additional_info
      #   end
      #
      def attribute(name, options = {})
        define_reader(name)
        define_writer(name, options) if options[:writable].nil? || options[:writable]

        attributes_set[name.to_sym] = options
      end

      # Removes attribute from the class (reader, writer and entry in Attributes Set).
      #
      # @param name [String, Symbol] attribute name
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :email
      #     attribute :name, default: 'John'
      #   end
      #
      #   class Person < User
      #     attribute :email
      #     remove_attribute :name
      #   end
      #
      def remove_attribute(name)
        symbolized_name = name.to_sym
        return unless attributes_set.keys.include?(symbolized_name)

        undef_method(symbolized_name)
        undef_method("#{name}=") if method_defined?("#{name}=")

        attributes_set.delete(symbolized_name)
      end

      private

      # Writes Attributes Set to the superclass on inheritance.
      #
      # @private
      #
      # @param subclass [Class] inherited class
      #
      def inherited(subclass)
        subclass.instance_variable_set(:@attributes_set, attributes_set.dup)
      end

      # Creates a reader method for the attribute.
      #
      # @private
      #
      # @param name [String, Symbol] attribute name
      #
      def define_reader(name)
        attr_reader name.to_sym
      end

      # Creates a writer method for the attribute with validation
      # of setting value if options[:values] was passed.
      #
      # @private
      #
      # @raise [InvalidAttributeValue] when value is not included in the possible values list
      # @raise [InvalidAttributeFormat] when value doesn't match the required format
      # @raise [InvalidAttributeType] when value is not of valid type
      #
      # @param name [Symbol] attribute name
      # @param options [Hash] attribute options
      #
      def define_writer(name, options = {})
        values = extract_values_from(options)
        format = extract_format_from(options)
        types = extract_types_from(options)

        define_method("#{name}=") do |value|
          raise InvalidAttributeValue.new(value, values) if values && !values.include?(value)

          raise InvalidAttributeFormat.new(value, format) if !format.nil? && value !~ format

          raise InvalidAttributeType.new(value, types) if value && types && types.none? { |klass| value.is_a?(klass) }

          instance_variable_set(:"@#{name}", value)
        end
      end

      # Extract and validate possible attribute values from options hash.
      #
      # @private
      #
      # @param options [Hash] attribute options
      #
      # @return [Array] possible attribute values
      #
      def extract_values_from(options = {})
        values = options[:values] || return

        unless values.is_a?(Array) || values.respond_to?(:to_a)
          raise ArgumentError, ':values option must be an Array or respond to #to_a!'
        end
        raise ArgumentError, ":values option can't be empty!" if values.empty?

        values.to_a
      end

      # Extract and validate attribute value format from options hash.
      #
      # @private
      #
      # @param options [Hash] attribute options
      #
      # @return [Regexp] attribute value format
      #
      def extract_format_from(options = {})
        format = options[:format] || return
        raise ArgumentError, ':format must be Regexp!' unless format.is_a?(Regexp)

        format
      end

      # Extract and validate attribute type class from options hash.
      #
      # @private
      #
      # @param options [Hash] attribute options
      #
      # @return [Object] possible attribute type(s)
      #
      def extract_types_from(options = {})
        types = Array(options[:type] || options[:types])
        return if types.empty?

        raise ArgumentError, 'attribute type must be a Class!' if types.any? { |type| !type.is_a?(Class) }

        types
      end
    end

    # Attributes class methods
    #   * initialize
    #   * attributes
    #   * []
    module InstanceMethods
      # Constructor supports setting attributes when creating a new instance of the class.
      # Sets default values for the attributes if they are present.
      #
      # @param attributes [Hash] attributes hash
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :email
      #     attribute :name, default: 'John'
      #   end
      #
      #   User.new(email: 'john.doe@gmail.com')
      #   #=> #<User:0x29cca00 @email='john.doe@gmail.com', @name="John">
      #
      def initialize(attributes = {})
        set_attributes_defaults!

        attributes.each do |name, value|
          set_attribute_safely(name, value)
        end
      end

      # Returns class instance attributes.
      #
      # @return [Hash] attributes of the instance object
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :email
      #     attribute :name, default: 'John'
      #   end
      #
      #   User.new.attributes
      #   #=> { email: nil, name: 'John' }
      #
      def attributes
        self.class.attributes_set.each_with_object({}) do |(name, _), attributes|
          attributes[name] = __send__(name)
        end
      end

      # Returns attribute value by it's name.
      #
      # @param name [String, Symbol] attribute name
      #
      # @return [Object] attribute value
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :email
      #   end
      #
      #   u = User.new(email: 'john@email.com')
      #   u[:email]
      #   #=> 'john@email.com'
      #
      def [](name)
        __send__(name)
      end

      # Returns names of the attributes that was marked as :required.
      #
      # @return [Array] array of attributes names
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :id
      #     attribute :email, required: true
      #     attribute :name, required: true
      #   end
      #
      #   u = User.new
      #   u.required_attributes
      #   #=> [:email, :name]
      #
      def required_attributes
        self.class.attributes_set.select { |_, options| options[:required] }.keys
      end

      # Indicates if all the attributes with option required: true
      # are filled with non-nil value.
      #
      # @return [Bool]
      #
      # @example
      #   class User
      #     include AlphaCard::Attribute
      #
      #     attribute :email, required: true
      #     attribute :name
      #   end
      #
      #   u = User.new
      #   u.required_attributes?
      #   #=> false
      #
      #   u.email = 'john.doe@gmail.com'
      #   u.required_attributes?
      #   #=> true
      #
      def required_attributes?
        required_attributes.all? { |attr| !self[attr].nil? }
      end

      protected

      # Set attribute value only if attribute writable
      #
      # @param name [String, Symbol] attribute name
      # @param value [Object] attribute value
      #
      def set_attribute_safely(name, value)
        __send__("#{name}=", value) if attribute_writable?(name)
      end

      # Checks if attribute is writable by it's options in the Attributes Set.
      #
      # @param name [String, Symbol] attribute name
      #
      # @return [Boolean]
      #
      def attribute_writable?(name)
        attribute_options = self.class.attributes_set[name.to_sym]
        return false if attribute_options.nil?

        attribute_options[:writable].nil? || attribute_options[:writable]
      end

      # Sets default values for the attributes, based on Attributes Set.
      def set_attributes_defaults!
        self.class.attributes_set.each do |attr_name, options|
          instance_variable_set(:"@#{attr_name}", options[:default])
        end
      end
    end
  end
end
