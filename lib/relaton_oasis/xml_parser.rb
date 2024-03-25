module RelatonOasis
  class XMLParser < RelatonBib::XMLParser
    class << self
      private

      # Override RelatonBib::XMLParser#item_data method.
      # @param node [Nokogiri::XML::Element]
      # @returtn [Hash]
      def item_data(node)
        data = super
        ext = node.at "./ext"
        return data unless ext

        data[:technology_area] = ext.xpath("./technology-area").map &:text
        data
      end

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        OasisBibliographicItem.new(**item_hash)
      end

      def create_doctype(type)
        DocumentType.new type: type.text, abbreviation: type[:abbreviation]
      end
    end
  end
end
