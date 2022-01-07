require 'core'

require_relative 'base'
require_relative 'models/user'

class Group < Base
  def initialize
    super

    get('/group/create', ->(req, _) {
      email = require_email(req)
      return 200, @slim.render('group/create', email: email)
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

    get(%r{^/group/view/(?<hash_id>.+)$}, ->(req, _) {
      email = require_email(req)
      group = require_group(req)

      member = group.member(email: email)
      return 404, @slim.render('group/not_found') unless member

      return 200, @slim.render('group/view', group: group, member: member)
    })

    post('/group/add_member', ->(req, _) {
    })

    post('/group/remove_member', ->(req, _) {
    })
  end
end
