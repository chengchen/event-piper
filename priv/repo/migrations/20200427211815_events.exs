defmodule EventPiper.Repo.Migrations.Events do

  use Ecto.Migration

  def change do
    create table(:events) do
      add :type,       :string      , null: false
      add :timestamp,  :utc_datetime, null: false
      add :subscriber, :string      , null: false
      add :payload,    :map         , null: false
    end

    create index(:events, :subscriber, name: :event_subscribers_index)
  end

end
