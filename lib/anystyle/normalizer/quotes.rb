# coding: utf-8
module AnyStyle
  class Normalizer
    class Quotes < Normalizer
      LEADING_QUOTES = /^[«‹»›„‚“‟‘‛”’"❛❜❟❝❞⹂〝〞〟\[]/
      TRAILING_QUOTES = /[«‹»›„‚“‟‘‛”’"❛❜❟❝❞⹂〝〞〟\]]\.?$/
      
      @keys = [:title, :'citation-number', :medium]

      def normalize(item, **opts)
        each_value(item) do |_, value|
          value.gsub!(LEADING_QUOTES, '')
          value.gsub!(TRAILING_QUOTES, '')
        end
      end
    end
  end
end
