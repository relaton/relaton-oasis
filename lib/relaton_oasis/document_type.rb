module RelatonOasis
  class DocumentType < RelatonBib::DocumentType
    DOCTYPES = %w[specification memorandum resolution standard].freeze

    def initialize(type:, abbreviation: nil)
      chceck_type type
      super
    end

    def chceck_type(type)
      unless DOCTYPES.include? type
        Util.warn "invalid doctype: `#{type}`"
      end
    end
  end
end
