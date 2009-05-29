class Subdomainer
  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @env = env
  end

  def call
    status, headers, body = Rack::File.new(domain_root).call(env)
    if status == 404
      status, headers, body = Rack::File.new(fallback_root).call(env)
    end
    [status, headers, body]
  end

  def fallback_root
    File.dirname(__FILE__) + "/default"
  end

  def domain_root
    File.dirname(__FILE__) + "/domains/#{request.server_name}"
  end

  def request
    @request ||= Rack::Request.new(@env)
  end
end

class WWWStrip
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    if request.server_name =~ /^www\.(.*)$/
      request.env["SERVER_NAME"] = $1
      [302, {"Location" => request.url}, []]
    else
      @app.call(env)
    end
  end
end

use Rack::CommonLogger
use WWWStrip
run Subdomainer

# vim:filetype=ruby
