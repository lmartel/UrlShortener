Sequel.migration do
  change do
    create_table(:links) do
        primary_key :id
        String :url, null: false
        String :short_url, null: false, unique: true
    end
  end
end
