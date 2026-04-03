defmodule PhoenixAuth.Repo.Migrations.AddUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :DOB, :date
    end
  end
end
