class AddEncryptedApiKeyToUsers < ActiveRecord::Migration[5.1]
    def change
        add_column :users, :encrypted_api_key, :string
        add_column :users, :encrypted_api_key_iv, :string
        remove_column :users, :api_key, :string
    end
end

