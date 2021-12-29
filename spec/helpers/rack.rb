module RSpec
  module Rack
    # rubocop:disable Style/StringHashKeys
    def post_json(path, data = {})
      post(path, data.to_json, { 'CONTENT_TYPE' => 'application/json' })
    end
    # rubocop:enable Style/StringHashKeys
  end
end
