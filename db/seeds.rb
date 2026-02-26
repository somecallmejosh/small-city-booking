# Admin user — change the password before deploying to production
User.find_or_create_by!(email_address: "admin@example.com") do |u|
  u.name = "Admin"
  u.password = "changeme123456"
  u.admin = true
end

# Initial StudioSetting record (singleton)
StudioSetting.find_or_create_by!(id: 1) do |s|
  s.hourly_rate_cents = 7500
  s.studio_name = "Small City Studio"
  s.studio_description = "Professional recording studio in East Hartford, CT."
  s.cancellation_hours = 24
end
