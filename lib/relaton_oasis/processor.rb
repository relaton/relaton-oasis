require "relaton/processor"

module RelatonOasis
  class Processor < Relaton::Processor
    def initialize # rubocop:disable Lint/MissingSuper
      @short = :relaton_oasis
      @prefix = "OASIS"
      @defaultprefix = %r{^OASIS\s}
      @idtype = "OASIS"
      @datasets = %w[oasis-open]
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonBib::BibliographicItem]
    def get(code, date, opts)
      ::RelatonOasis::OasisBibliography.get(code, date, opts)
    end

    #
    # Fetch all the documents from https://www.oasis-open.org/standards/
    #
    # @param [String] source source name
    # @param [Hash] opts
    # @option opts [String] :output directory to output documents
    # @option opts [String] :format
    #
    def fetch_data(_source, opts)
      DataFetcher.fetch(**opts)
    end

    # @param xml [String]
    # @return [RelatonBib::BibliographicItem]
    def from_xml(xml)
      ::RelatonOasis::XMLParser.from_xml xml
    end

    # @param hash [Hash]
    # @return [RelatonBib::BibliographicItem]
    def hash_to_bib(hash)
      ::RelatonOasis::OasisBibliographicItem.from_hash hash
    end

    # Returns hash of XML grammar
    # @return [String]
    def grammar_hash
      @grammar_hash ||= ::RelatonOasis.grammar_hash
    end

    #
    # Remove index file
    #
    def remove_index_file
      Relaton::Index.find_or_create(:oasis, url: true, file: OasisBibliography::INDEX_FILE).remove_file
    end
  end
end
