module Roadie
  class MarkupImprover
    def initialize(dom, original_html)
      @dom = dom
      @html = original_html
    end

    def improve
      ensure_doctype
      head = ensure_head_element
      ensure_charset_element head
    end

    private
    attr_reader :dom

    def ensure_doctype
      return if @html.include?('<!DOCTYPE ')
      # Nokogiri adds a "default" doctype to the DOM, which we will remove
      dom.internal_subset.remove unless dom.internal_subset.nil?
      dom.create_internal_subset 'html', nil, nil
    end

    def ensure_head_element
      if (head = dom.at_xpath('html/head'))
        head
      else
        head = Nokogiri::XML::Node.new('head', dom)
        html = dom.at_xpath('html')
        if html.children.size > 0
          html.children.before(head)
        else
          html << head
        end
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
