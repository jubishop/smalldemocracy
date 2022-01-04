require_relative 'shared_examples/entity_flows'

RSpec.describe(Group, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/group') }

  let(:entity) { create_group }
  it_has_behavior('entity flows', 'group')
}
