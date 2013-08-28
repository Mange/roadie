module Roadie
  class MarkupImprover
    def initialize(dom)
      @dom = dom
    end

    def improve
      head = ensure_head_element
      ensure_charset_element head
    end

    private
    attr_reader :dom

    def ensure_head_element
      if (head = dom.at_xpath('html/head'))
        head
      else
        head = Nokogiri::XML::Node.new('head', dom)
        dom.at_xpath('html').children.before(head)
        head
      end
    end

    def ensure_charset_element(parent)
      if content_type_meta_element_missing?
        parent.add_child make_content_type_element
      end
    end

    def content_type_meta_element_missing?
      dom.xpath('html/head/meta').none? do |meta|
        meta['http-equiv'].downcase == 'content-type'
      end
    end

    def make_content_type_element
      meta = Nokogiri::XML::Node.new('meta', dom)
      meta['http-equiv'] = 'Content-Type'
      meta['content'] = 'text/html; charset=UTF-8'
      meta
    end
  end
end
