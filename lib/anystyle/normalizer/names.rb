# coding: utf-8
module AnyStyle
  require 'namae' # Namae is a parser for human names.

  class Normalizer
    class Names < Normalizer
      @keys = [
        :author, :editor, :translator, :director, :producer
      ]

      attr_accessor :namae

      def initialize(**opts)
        super(**opts)

        @namae = Namae::Parser.new({
          prefer_comma_as_separator: true,
          separator: /\A(and|AND|&|;|und|UND|y|e|och|OCH)\s+/,
          appellation: /\A(?!x)x/,
          title: /\A(?!x)x/
        })
      end

      def correct(value)
        value.gsub(/et\.al/, 'et al')
      end

      def normalize(item, prev: [], **opts)
        map_values(item) do |key, value|
          value.gsub!(/(^[\(\[]|[,;:\)\]]+$)/, '')
          case
          when repeater?(value) && prev.length > 0
            prev[-1].dig(key, 0) || prev[-1].dig(:author, 0) || prev[-1].dig(:editor, 0)
          else
            begin
              # Don't parse the name of organizations
              if organization?(value)
                [{ literal: value.strip.gsub(/\.$/,'') }]
              else
                parse(strip(correct(value)))
              end
            rescue
              [{ literal: value.strip }]
            end
          end
        end
      end

      def repeater?(value)
        value =~ /^([\p{Pd}_*][\p{Pd}_* ]+|\p{Co})(,|:|\.|$)/
      end

      def strip(value)
        value
          .gsub(/^[Ii]n?:?\s+/, '')
          .gsub(/\b[EÉeé]d(s?\.|itors?\.?|ited|iteurs?|ité)(\s+(by|par)\s+|\b|$)/, '')
          .gsub(/\b([Hh]uvud)?red(aktör)?(er)?/,'')
          .gsub(/\b([Hh](rsg|gg?)\.|Herausgeber)\s+/, '')
          .gsub(/\b[Hh]erausgegeben von\s+/, '')
          .gsub(/\b((d|ein)er )?[Üü]ber(s\.|setzt|setzung|tragen|tragung) v(\.|on)\s+/, '')
          .gsub(/\b[Tt]rans(l?\.|lated|lation)(\s+by\b)?\s*/, '')
          .gsub(/\b([Ss]vensk\s)?[Öö]vers(att|ättning)(\s+av\b)?\s*/, '')
          .gsub(/\b[Tt]rad(ucteurs?|(uit|\.)(\s+par\b)?)\s*/, '')
          .gsub(/\b([Dd]ir(\.|ected))(\s+by)?\s+/, '')
          .gsub(/\b([Pp]rod(\.|uce[rd]))(\s+by)?\s+/, '')
          .gsub(/\b([Pp]erf(\.|orme[rd]))(\s+by)?\s+/, '')
          .gsub(/\*/, '')
          .gsub(/\([^\)]*\)?/, '')
          .gsub(/\[[^\]]*\)?/, '')
          .gsub(/[;:]/, ',')
          .gsub(/^\p{^L}+|\s*\p{^L}+$/, '')
          .gsub(/[\s,\.]+$/, '')
          .gsub(/,{2,}/, ',')
          .gsub(/\s+\./, '.')
      end

      def organization?(value)
        components = value.split(/\s+(and|AND|&|;|und|UND|y|e|och|OCH)\s+/)

        components.any? do |component|
          contains_org_keyword = component.match?(/\b(Institute|University|Organization|Association|Society|Corporation|Corp|Inc|Ltd|Department|Agency|Committee|Council)\b/i)
          ends_with_org_suffix = component.match?(/verket$/i)
          all_capitalized = component.split.all? { |word| word.match?(/\b[A-Z]+\b/) }

          contains_org_keyword || ends_with_org_suffix || all_capitalized
        end
      end

      def parse(value)
        raise ArgumentError if value.empty?

        others = value.sub!(
          /(,\s+)?((\&\s+)?\bet\s+(al|coll)\b|\bu\.\s*a\b|(\band|\&)\s+others|(\boch\b\s+andra|m\.?\s*fl\.?|et\s+al))\s*\.*$/, ''
        ) || value.sub!(/\.\.\.|…/, '')

        # Add surname/initial punctuation separator for Vancouver-style names
        # E.g. Rang HP, Dale MM, Ritter JM, Moore PK
        if value.match(/^(\p{Lu}[^\s,.]+)\s+([\p{Lu}][\p{Lu}\-]{0,3})(,|[.]?$)/)
          value.gsub!(/\b(\p{Lu}[^\s,.]+)\s+([\p{Lu}][\p{Lu}\-]{0,3})(,|[.]?$)/, '\1, \2\3')
        end

        if value.match(/^\b[A-Z][a-z]{1,}(,\s\b[A-Z][a-z]{1,}){2,}/)
          puts value
        end

        names = namae.parse!(value).map { |name|
          name.normalize_initials
          name.to_h.reject { |_, v| v.nil? }
        }

        names << { others: true } unless others.nil?
        names
      end
    end
  end
end
