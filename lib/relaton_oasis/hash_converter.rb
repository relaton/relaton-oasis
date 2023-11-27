module RelatonOasis
  module HashConverter
    include RelatonBib::HashConverter
    extend self

    @@acronyms = nil

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
