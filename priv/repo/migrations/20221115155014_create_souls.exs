defmodule Grim.Test.Repo.Migrations.CreateSouls do
  use Ecto.Migration

  def change do
    create table(:souls) do
      add(:soul_id, :uuid, primary_key: true)

      timestamps()
    end

  end
end
