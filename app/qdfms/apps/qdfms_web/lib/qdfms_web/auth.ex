defmodule QdfmsWeb.Auth do
  # OTP Auth code should eventually move elsewhere, it doesn't belong in the LiveView
  secret = "CHANGEME1337"

  def gen_totp_url(secret) do
    "otpauth://totp/QdfmsWeb:admin@admin?secret=#{secret}&issuer=TOTP%QdfmsWeb&algorithm=SHA1&digits=6&period=30"
  end

  def validate_token(token,secret) do
    :pot.valid_totp(token, secret)
  end

  defp generate_totp_code(secret) do
    :pot.totp(secret)
  end

end
