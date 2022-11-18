defmodule Grim.Schema do
  @moduledoc """
  This module should be used when defining Ecto schemas and provides options that all schemas share.

  ## Example

      defmodule Grim.Widgets.Widget do
        use Grim.Schema

        import Ecto.Changeset

        @derive {Phoenix.Param, key: :widget_id}
        schema "widgets" do
          # fields
        end
      end
  """
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      @primary_key false
      @foreign_key_type Ecto.UUID
      @timestamps_opts [type: :utc_datetime]
    end
  end
end
