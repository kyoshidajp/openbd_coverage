require 'google_drive'
require 'oauth2'
require 'openbd'

SPREAD_KEY = '1c0oOtbhKwgJ7laU8C5aW2SIeHe2zPljhZXxn5Xeiin8'.freeze

class Recorder
  def record
    refresh_token = ENV['GOOGLE_REFRESH_TOKEN']
    auth_token = OAuth2::AccessToken.from_hash(oauth_client,
                                               { refresh_token: refresh_token,
                                                 expires_at: 3600})
    auth_token = auth_token.refresh!
    #auth_token.refresh!
    session = GoogleDrive.login_with_oauth(auth_token.token)
    ws = session.spreadsheet_by_key(SPREAD_KEY).worksheets[0]
    add_count(ws)
  end

  private

  def oauth_client
    client_id     = ENV['GOOGLE_CLIENT_ID']
    client_secret = ENV['GOOGLE_CLIENT_SECRET']
    OAuth2::Client.new(
      client_id,
      client_secret,
      site: 'https://accounts.google.com',
      token_url: '/o/oauth2/token',
      authorize_url: '/o/oauth2/auth'
    )
  end

  def add_count(ws)
    row = ws.num_rows + 1
    now = Time.now
    access_date = now.strftime('%Y/%m/%d')
    access_datetime = now.to_s

    if data_exists?(ws, access_date)
      puts 'Already logged.'
      return
    end

    post(ws, row, access_date, access_datetime)
  end

  def post(ws, row, access_date, access_datetime)
    value = coverage.size
    ws[row, 1] = access_date
    ws[row, 2] = value
    ws[row, 3] = access_datetime
    ws.save
    puts "#{access_date}, #{value}"
  end

  def data_exists?(ws, today)
    ws.num_rows.downto(1).any? do |n|
      ws[n, 1] == today && ws[n, 2] =~ /^\d+$/
    end
  end

  def coverage
    client = Openbd::Client.new
    client.coverage
  end
end

if __FILE__ == $PROGRAM_NAME
  recorder = Recorder.new
  recorder.record
end
