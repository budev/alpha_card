module AlphaCard
  ##
  # Alpha Card resource base class.
  class Resource
    # Attributes DSL
    include AlphaCard::Attribute

    ##
    # Original AlphaCard transaction variables names
    ORIGIN_TRANSACTION_VARIABLES = {}.freeze

    ##
    # Returns only filled attributes with the original Alpha Card Services
    # transaction variables names.
    #
    # @param [Hash] attrs
    #   Attributes that must be converted to AlphaCard request params/
    #   Default value is <code>filled_attributes</code>.
    #
    # @example
    #   order = AlphaCard::Order.new(id: '1', tax: nil, po_number: 'PO123')
    #   order.send(:attributes_for_request)
    #
    #   #=> { orderid: '1', ponumber: 'PO123' }
    def attributes_for_request(attrs = filled_attributes)
      return attrs if self.class::ORIGIN_TRANSACTION_VARIABLES.empty?

      attrs.each_with_object({}) do |(attr, value), request_attrs|
        request_attrs[self.class::ORIGIN_TRANSACTION_VARIABLES.fetch(attr, attr)] = value
      end
    end

    protected

    ##
    # Returns the <code>Hash</code> with only filled attributes
    # of the <code>AlphaCard::AlphaCardObject</code>.
    #
    # @return [Hash]
    #   Filled attributes of the <code>AlphaCard::AlphaCardObject</code>.
    #
    # @example
    #   order = AlphaCard::Order.new(id: '1', tax: nil, po_number: 'PO123')
    #   order.filled_attributes
    #
    #   #=> { id: '1', po_number: 'PO123' }
    def filled_attributes
      attributes.select { |_, value| !value.nil? }
    end

    ##
    # Validate passed attributes for presence. Raises an exception
    # if one of the attribute is not specified.
    #
    # @param [Array] attributes
    #   array of attributes to check
    def abort_if_attributes_blank!(*attributes)
      attributes.each do |attr|
        raise InvalidObjectError, "#{attr} must be present!" if self[attr].nil? || self[attr].empty?
      end
    end
  end
end
