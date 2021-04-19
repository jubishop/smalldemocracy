class AdminOnlyAuth < Rack::Auth::Basic
  def call(env)
    if Rack::Request.new(env).path.start_with?('/admin')
      super(env)
    else
      @app.call(env)
    end
  end
end
