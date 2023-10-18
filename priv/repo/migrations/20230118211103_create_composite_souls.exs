defmodule Grim.Test.Repo.Migrations.CreateCompositeSouls do
  use Ecto.Migration

  def change do
    create table(:composite_souls) do
      add :composite_soul_id, :uuid, primary_key: true
      add :tenant_id, :uuid, primary_key: true
      add :string_id, :string, primary_key: true

      timestamps()
    end
  end
end
