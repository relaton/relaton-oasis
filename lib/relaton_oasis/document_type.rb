module RelatonOasis
  class DocumentType < RelatonBib::DocumentType
    DCTYPES = %w[specification memorandum resolution standard].freeze

    def initialize(type:, abbreviation: nil)
      chceck_type type
      super
    end

    def chceck_type(type)
      unless DCTYPES.include? type
        Util.warn "WARNING: invalid doctype: `#{type}`"
      end
    end
  end
end
