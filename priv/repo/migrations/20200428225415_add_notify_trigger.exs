defmodule EventPiper.Repo.Migrations.AddNotifyTrigger do

  use Ecto.Migration

  def change do
    execute "CREATE OR REPLACE FUNCTION notify_new_event()
      RETURNS trigger AS $$
      BEGIN
        PERFORM pg_notify('new_events', row_to_json(NEW)::text);

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;"

    execute "CREATE TRIGGER event_created
      AFTER INSERT
      ON events
      FOR EACH ROW
      EXECUTE PROCEDURE notify_new_event()"
  end

end
