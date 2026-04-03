defmodule PhoenixAuth.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_auth,
    adapter: Ecto.Adapters.Postgres
end
