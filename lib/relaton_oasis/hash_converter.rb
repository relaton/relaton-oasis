module RelatonOasis
  class HashConverter < RelatonBib::HashConverter
    @@acronyms = nil

    class << self
      private

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        OasisBibliographicItem.new(**item_hash)
      end
    end
  end
end
