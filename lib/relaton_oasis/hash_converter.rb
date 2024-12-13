module RelatonOasis
  module HashConverter
    include RelatonBib::HashConverter
    extend self

    @@acronyms = nil

    def hash_to_bib(hash)
      ret = super
      ret[:technology_area] = ret[:ext][:technology_area] if ret.dig(:ext, :technology_area)
      ret
    end

    private

    # @param item_hash [Hash]
    # @return [RelatonBib::BibliographicItem]
    def bib_item(item_hash)
      OasisBibliographicItem.new(**item_hash)
    end

    def create_doctype(**args)
      DocumentType.new(**args)
    end
  end
end
