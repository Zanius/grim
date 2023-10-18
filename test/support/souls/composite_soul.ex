defmodule Grim.Test.Souls.CompositeSoul do
  use Grim.Schema

  @primary_key {:composite_soul_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "composite_souls" do
    field(:tenant_id, Ecto.UUID, primary_key: true, autogenerate: true)
    field(:string_id, :string, primary_key: true)

    timestamps()
  end
end
