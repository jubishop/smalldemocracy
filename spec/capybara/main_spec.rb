require 'duration'

RSpec.describe(Main, type: :feature) {
  let(:goldens) { Tony::Test::Goldens::Page.new(page, 'spec/goldens/main') }
  let(:time) {
    Time.new(1982, 6, 6, 11, 30, 0, TZInfo::Timezone.get('Asia/Bangkok'))
  }

  context(:index) {
    def expect_header_links
      expect(page).to(have_selector('a.home[href="/"]'))
      github_url = 'https://github.com/jubishop/smalldemocracy'
      expect(page).to(have_selector("a.github[href='#{github_url}']"))
    end

    it('displays logged out index') {
      go('/')
      expect_header_links
      expect(page).to(have_link('Sign in with Google', href: '/'))
      goldens.verify('logged_out')
    }

    it('displays logged in index with empty group and poll sections') {
      set_cookie(:email, 'logged_in_no_data@main.com')
      go('/')
      expect_header_links
      expect(page).to(have_link('Create Poll', href: '/poll/create'))
      expect(page).to(have_link('Create Group', href: '/group/create'))
      goldens.verify('logged_in_no_data')
    }

    it('displays logged in index with groups and polls') {
      freeze_time(time)

      # Create poll and group data to see on the page.
      user = create_user(email: 'logged_in_with_data@main.com')
      3.times { |i| create_group(email: user.email, name: "group_#{i}") }
      3.times { |i|
        create_poll(email: user.email,
                    group_id: user.groups.first.id,
                    title: "active_poll_#{i}",
                    expiration: future + i.minutes)
      }
      3.times { |i|
        create_poll(email: user.email,
                    group_id: user.groups.last.id,
                    title: "past_poll_#{i}").update(
                        expiration: past - i.minutes)
      }

      set_cookie(:email, user.email)
      go('/')
      expect_header_links
      expect(page).to(have_link('Create Poll', href: '/poll/create'))
      expect(page).to(have_link('Create Group', href: '/group/create'))

      # Confirm links to all our groups and polls are accurate.
      user.groups.each { |group|
        expect(page).to(have_link(group.name, href: group.url))
      }
      user.polls.each { |poll|
        expect(page).to(have_link(poll.title, href: poll.url))
      }

      goldens.verify('logged_in_with_data')
    }
  }

  context('not found') {
    it('displays a not found page') {
      go('/does_not_exist')
      expect(page).to(
          have_link('report',
                    href: 'https://github.com/jubishop/smalldemocracy/issues'))
      goldens.verify('not_found')
    }
  }
}
