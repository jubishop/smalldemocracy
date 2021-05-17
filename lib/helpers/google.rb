require 'base64'

module Tony
  module Auth
    LoginInfo = Struct.new(:email, :state, keyword_init: true)
    private_constant :LoginInfo

    class Google
      @@paths = {}
      def self.url(req, path: '/auth/google', scope: 'email', **state)
        info = @@paths.fetch(path)
        uri = URI('https://accounts.google.com/o/oauth2/v2/auth')
        uri.query = URI.encode_www_form(
            client_id: info.fetch(:client_id),
            redirect_uri: "#{req.base_url}#{path}",
            response_type: 'code',
            scope: scope,
            state: Base64.urlsafe_encode64(JSON.dump(state), padding: false))
        return uri.to_s
      end

      def initialize(app, client_id:, secret:, path: '/auth/google')
        @app = app
        @path = path
        @client_id = client_id
        @secret = secret
        @@paths[path] = { client_id: client_id, secret: secret }
      end

      def call(env)
        req = Rack::Request.new(env)
        fetch_login_info(req) if req.path == '/auth/google'
        @app.call(env)
      end

      private

      def fetch_login_info(req)
        uri = URI('https://oauth2.googleapis.com/token')
        res = Net::HTTP.post_form(
            uri,
            client_id: @client_id,
            client_secret: @secret,
            code: req.params['code'],
            grant_type: 'authorization_code',
            redirect_uri: "#{req.base_url}#{@path}")
        info = JSON.parse(res.body)

        uri = URI('https://oauth2.googleapis.com/tokeninfo')
        uri.query = URI.encode_www_form(id_token: info['id_token'])
        res = Net::HTTP.get_response(uri)
        info = JSON.parse(res.body)

        state = JSON.parse(Base64.urlsafe_decode64(req.params['state']))
        state.symbolize_keys!
        req.env[:login_info] = LoginInfo.new(email: info['email'], state: state)
      end
    end
  end
end
