require 'core'

require_relative 'base'
require_relative 'models/user'

class Group < Base
  def initialize
    super

    get('/group/create', ->(req, _) {
      email = require_session(req)
      return 200, @slim.render('group/create', email: email)
    })

    post('/group/create', ->(req, resp) {
      email = require_session(req)
      req.params[:email] = email

      members = req.list_param(:members, [])
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
      email = require_session(req)
      group = require_group(req)

      member = group.member(email: email)
      return 404, @slim.render('group/not_found') unless member

      return 200, @slim.render('group/view', group: group, member: member)
    })

    post('/group/add_member', ->(req, _) {
      group = require_creator(req)
      member_email = req.param(:email)

      begin
        group.add_member(email: member_email)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Group member added'
      end
    })

    post('/group/remove_member', ->(req, _) {
      group = require_creator(req)
      member_email = req.param(:email)

      if member_email == group.email
        return 400, 'Cannot remove the creator of a group'
      end

      member = group.member(email: member_email)
      unless member
        return 400, "#{member_email} is not a member of #{group.name}"
      end

      begin
        group.remove_member(member)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Group member removed'
      end
    })

    post('/group/name', ->(req, _) {
      group = require_creator(req)
      name = req.param(:name)

      begin
        group.update(name: name)
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Group name changed'
      end
    })

    post('/group/destroy', ->(req, _) {
      group = require_creator(req)

      begin
        group.destroy
      rescue Sequel::Error => error
        return 400, error.message
      else
        return 201, 'Group destroyed'
      end
    })
  end

  private

  def require_creator(req)
    email = require_session(req)
    group = require_group(req)

    unless email == group.email
      throw(:response, [400, "#{email} is not the creator of #{group.name}"])
    end

    return group
  end
end
