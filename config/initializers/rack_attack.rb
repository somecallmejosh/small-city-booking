Rack::Attack.throttle("login/ip", limit: 5, period: 60) do |req|
  req.ip if req.post? && req.path == "/session"
end

Rack::Attack.throttle("signup/ip", limit: 10, period: 600) do |req|
  req.ip if req.post? && req.path == "/users"
end
