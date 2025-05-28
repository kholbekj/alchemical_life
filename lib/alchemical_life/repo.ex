defmodule AlchemicalLife.Repo do
  use Ecto.Repo,
    otp_app: :alchemical_life,
    adapter: Ecto.Adapters.SQLite3
end
