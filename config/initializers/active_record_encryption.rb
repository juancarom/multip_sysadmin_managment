Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY',
                                                          '3AUr3S1H9sRzeUNYXxviCJmMk6B3cqTf')
  config.active_record.encryption.deterministic_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY',
                                                                'Bvu0moXzbtcwxJGkk74J37COkKvdDMbr')
  config.active_record.encryption.key_derivation_salt = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT',
                                                                  't9ieMJEGmE9iGi9FRv4tAhJ4mLeAqrTF')
end
