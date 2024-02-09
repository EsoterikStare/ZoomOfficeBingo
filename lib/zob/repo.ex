defmodule Zob.Repo do
  use Ecto.Repo,
    otp_app: :zob,
    adapter: Ecto.Adapters.Postgres
end
