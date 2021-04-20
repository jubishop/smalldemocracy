module Helpers
  module Slim
    def slim_email(template, **options)
      slim(template, **options.merge(views: 'views/email',
                                     layout: :'../layout'))
    end

    def slim_poll(template, **options)
      slim(template, **options.merge(views: 'views/poll', layout: :'../layout'))
    end
  end
end
