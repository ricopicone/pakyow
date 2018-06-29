# frozen_string_literal: true

%w(
  assets
  core
  data
  mailer
  presenter
  realtime
  reflection
  support
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
