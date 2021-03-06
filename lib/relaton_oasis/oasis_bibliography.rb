# frozen_string_literal: true

module RelatonOasis
  # Class methods for search Cenelec standards.
  class OasisBibliography
    ENDPOINT = "https://raw.githubusercontent.com/relaton/relaton-data-oasis/main/data/"

    class << self
      # @param text [String]
      # @return [RelatonOasis::HitCollection]
      def search(text, _year = nil)
        /^(?:OASIS\s)?(?<code>.+)/ =~ text
        agent = Mechanize.new
        resp = agent.get "#{ENDPOINT}#{code.upcase}.yaml"
        return unless resp.code == "200"

        hash = YAML.safe_load resp.body
        OasisBibliographicItem.from_hash hash
      rescue Mechanize::ResponseCodeError => e
        return if e.response_code == "404"

        raise RelatonBib::RequestError, e.message
      end

      # @param code [String] the CEN standard Code to look up
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts
      #   reference is required
      # @return [RelatonOasis::OasisBibliographicItem, nil]
      def get(code, year = nil, _opts = {}) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        warn "[relaton-oasis] (#{code} fetching..."
        bibitem = search code, year
        if bibitem
          docid = bibitem.docidentifier.detect(&:primary).id
          warn "[relaton-oasis] (#{code}) found #{docid}"
          bibitem
        else
          warn "[relaton-oasis] (#{code}) not found"
        end
      end
    end
  end
end
