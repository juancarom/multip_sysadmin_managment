require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe 'validations' do
    subject { build(:admin_user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(AdminUser.devise_modules).to include(:database_authenticatable)
    end

    it 'includes recoverable' do
      expect(AdminUser.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(AdminUser.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(AdminUser.devise_modules).to include(:validatable)
    end
  end

  describe 'authentication' do
    let(:admin_user) { create(:admin_user, password: 'password123') }

    it 'authenticates with valid password' do
      expect(admin_user.valid_password?('password123')).to be true
    end

    it 'does not authenticate with invalid password' do
      expect(admin_user.valid_password?('wrong_password')).to be false
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:admin_user)).to be_valid
    end

    it 'creates admin user successfully' do
      admin_user = create(:admin_user)
      expect(admin_user).to be_persisted
      expect(admin_user.email).to be_present
    end
  end
end
