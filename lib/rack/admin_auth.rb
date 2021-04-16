class AdminOnlyAuth < Rack::Auth::Digest::MD5
  def call(env)
    if Rack::Request.new(env).path.start_with?('/admin')
      super(env)
    else
      @app.call(env)
    end
  end
end
