RSpec::Matchers.define :have_node do |selector|
  chain(:with_attributes) { |attributes| @attributes = attributes }
  match do |document|
    node = document.at_css(selector)
    if @attributes
      node.present? and match_attributes(node.attributes)
    else
      node.present?
    end
  end

  failure_message_for_should { "expected document to #{name_to_sentence}#{expected_to_sentence}"}
  failure_message_for_should_not { "expected document to not #{name_to_sentence}#{expected_to_sentence}"}

  def match_attributes(node_attributes)
    attributes = Hash[node_attributes.map { |name, attribute| [name, attribute.value] }]
    @attributes == attributes
  end
end
