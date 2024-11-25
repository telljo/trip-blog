# lib/middleware/set_remote_ip.rb
class SetRemoteIp
  def initialize(app)
    @app = app
  end

  def call(env)
    env["REMOTE_ADDR"] = "81.38.174.158"
    @app.call(env)
  end
end
