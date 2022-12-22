import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :qdfms_web, QdfmsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DrB8w4TA5s+3xSOOpUJqHta7PX5ZMCs4eVN327S87VUfh5YyiMz4Ss4P1dssWLni",
  server: false
