# frozen_string_literal: true

require "mechanize"
require "relaton/index"
require "relaton_bib"
require_relative "relaton_oasis/version"
require_relative "relaton_oasis/util"
require_relative "relaton_oasis/document_type"
require_relative "relaton_oasis/oasis_bibliographic_item"
require_relative "relaton_oasis/xml_parser"
require_relative "relaton_oasis/hash_converter"
require_relative "relaton_oasis/oasis_bibliography"
require_relative "relaton_oasis/data_fetcher"
require_relative "relaton_oasis/data_parser_utils"
require_relative "relaton_oasis/data_parser"
require_relative "relaton_oasis/data_part_parser"
require_relative "relaton_oasis/index"

module RelatonOasis
  class Error < StandardError; end
  # Your code goes here...

  # Returns hash of XML reammar
  # @return [String]
  def self.grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest RelatonOasis::VERSION + RelatonBib::VERSION # grammars
  end
end
