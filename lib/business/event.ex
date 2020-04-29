defmodule EventPiper.Event do

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :type, :timestamp, :subscriber, :payload]}
  schema "events" do
    field :type,       :string      , null: false
    field :timestamp,  :utc_datetime, null: false
    field :subscriber, :string      , null: false
    field :payload,    :map         , null: false
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:type, :timestamp, :subscriber, :payload])
    |> validate_required([:type, :timestamp, :subscriber, :payload])
  end

end
