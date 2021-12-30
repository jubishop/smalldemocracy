require 'core'

require_relative 'base'
require_relative 'models/user'

class Group < Base
  def initialize
    super

    get('/group/create', ->(req, _) {
      require_email(req)
      return 200, @slim.render('group/create')
    })

    post('/group/create', ->(req, resp) {
      email = require_email(req)
      req.params[:email] = email

      members = list_param(req, :members)
      req.params.delete(:members)

      begin
        group = Models::Group.create(**req.params.symbolize_keys)
        members.each { |member| group.add_member(email: member) }
      rescue Sequel::Error => error
        return 400, error.message
      else
        resp.redirect(group.url)
      end
    })
  end
end
