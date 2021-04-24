module RSpec
  module MainExpectations
    def expect_logged_out_index_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_no_link(href: '/logout'))
    end

    def expect_logged_in_index_page(email)
      expect(last_response.body).to(have_content(email))
      expect(last_response.body).to(have_link(href: '/poll/create'))
      expect(last_response.body).to(have_link(href: '/logout'))
    end
  end
end
