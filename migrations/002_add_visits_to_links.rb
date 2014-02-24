Sequel.migration do
	change do
		alter_table(:links) do
			add_column :visits, Integer, default: 0
		end
	end	
end