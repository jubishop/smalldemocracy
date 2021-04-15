module Sinatra
  module HeadTags
    def google_fonts(*fonts)
      families = fonts.map { |font| "family=#{font}" }.join('&')
      source = "https://fonts.googleapis.com/css2?#{families}&display=swap"
      <<~HTML
        #{preconnect_link_tag('https://fonts.gstatic.com')}
        #{stylesheet_link_tag(source)}
      HTML
    end
  end
end
