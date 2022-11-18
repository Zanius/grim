defmodule Grim.Test.Souls.Soul do
  use Grim.Schema

  @primary_key {:soul_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "souls" do
    timestamps()
  end
end
