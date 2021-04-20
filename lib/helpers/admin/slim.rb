module AdminHelpers
  module Slim
    def slim_admin(template, **options)
      slim(template, **options.merge(views: 'views/admin',
                                     layout: :'../layout'))
    end
  end
end
