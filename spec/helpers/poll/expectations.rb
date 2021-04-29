module RSpec
  module PollExpectations
    def expect_create_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(
          have_selector('form[action="/poll/create"][method=post]'))
      expect(last_response.body).to(have_selector('input[type=submit]'))
    end

    def expect_email_not_found_page
      expect(last_response.ok?).to(be(false))
      expect(last_response.body).to(have_content('Email Not Found'))
    end

    def expect_email_get_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_selector('h1', text: 'Need Email'))
    end

    def expect_email_sent_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_selector('h1', text: 'Sent Email'))
    end

    def expect_finished_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_content('is finished'))
    end

    def expect_not_found_page
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(have_selector('h1', text: 'Poll Not Found'))
    end

    def expect_responded_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_content('your recorded responses'))
    end

    def expect_responder_not_found_page
      expect(last_response.status).to(be(404))
      expect(last_response.body).to(have_selector('h1',
                                                  text: 'Email Not Found'))
    end

    def expect_view_borda_single_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_selector('ul#choices'))
      expect(last_response.body).to(have_no_selector('ul#bottom-choices'))
    end

    def expect_view_borda_split_page
      expect(last_response.ok?).to(be(true))
      expect(last_response.body).to(have_selector('ul#choices'))
      expect(last_response.body).to(have_selector('ul#bottom-choices'))
    end
  end
end
