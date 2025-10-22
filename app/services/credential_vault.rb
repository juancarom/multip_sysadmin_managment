class CredentialVault
  ENCRYPTION_KEY = Rails.application.credentials.encryption_key || ENV['CREDENTIALS_ENCRYPTION_KEY']

  def self.encrypt(data)
    return nil if data.nil?

    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = generate_key
    iv = cipher.random_iv

    encrypted_data = cipher.update(data.to_json) + cipher.final

    # Combine IV and encrypted data, then encode
    Base64.strict_encode64(iv + encrypted_data)
  end

  def self.decrypt(encrypted_data)
    return nil if encrypted_data.nil?

    data = Base64.strict_decode64(encrypted_data)

    # Extract IV and encrypted content
    iv = data[0, 16]
    encrypted_content = data[16..-1]

    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = generate_key
    cipher.iv = iv

    decrypted_data = cipher.update(encrypted_content) + cipher.final
    JSON.parse(decrypted_data)
  rescue StandardError => e
    Rails.logger.error "Failed to decrypt credentials: #{e.message}"
    nil
  end

  def self.generate_key
    OpenSSL::Digest.digest('SHA256', ENCRYPTION_KEY.to_s)
  end

  private_class_method :generate_key
end
