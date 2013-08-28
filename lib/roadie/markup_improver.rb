module Roadie
  class MarkupImprover
    def initialize(dom)
      @dom = dom
    end

    def improve
      add_missing_structure
    end

    private
    attr_reader :dom

    def add_missing_structure
      html_node = dom.at_css('html')
      html_node['xmlns'] ||= 'http://www.w3.org/1999/xhtml'

      if dom.at_css('html > head')
        head = dom.at_css('html > head')
      else
        head = Nokogiri::XML::Node.new('head', dom)
        dom.at_css('html').children.before(head)
      end

      # This is handled automatically by Nokogiri in Ruby 1.9, IF charset of string != utf-8
      # We want UTF-8 to be specified as well, so we still do this.
      unless dom.at_css('html > head > meta[http-equiv=Content-Type]')
        meta = Nokogiri::XML::Node.new('meta', dom)
        meta['http-equiv'] = 'Content-Type'
        meta['content'] = 'text/html; charset=UTF-8'
        head.add_child(meta)
      end
    end
  end
end
