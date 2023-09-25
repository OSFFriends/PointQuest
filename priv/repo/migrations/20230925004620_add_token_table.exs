defmodule PointQuest.Repo.Migrations.AddTokenTable do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :expiration, :utc_datetime, null: false
      add :provider, :string, null: false
    end

    create unique_index(:tokens, [:user_id])
  end
end
