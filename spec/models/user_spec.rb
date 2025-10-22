require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:role) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
  end

  describe 'associations' do
    it { should have_many(:user_projects).dependent(:destroy) }
    it { should have_many(:projects).through(:user_projects) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1, superadmin: 2) }
  end

  describe '#can_manage_projects?' do
    it 'returns true for admin' do
      user = build(:user, :admin)
      expect(user.can_manage_projects?).to be true
    end

    it 'returns true for superadmin' do
      user = build(:user, :superadmin)
      expect(user.can_manage_projects?).to be true
    end

    it 'returns false for regular user' do
      user = build(:user)
      expect(user.can_manage_projects?).to be false
    end
  end

  describe '#accessible_projects' do
    let(:superadmin) { create(:user, :superadmin) }
    let(:admin) { create(:user, :admin) }
    let(:regular_user) { create(:user) }
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    before do
      create(:user_project, user: admin, project: project1)
      create(:user_project, user: regular_user, project: project1)
    end

    it 'superadmin can access all projects' do
      expect(superadmin.accessible_projects).to include(project1, project2)
    end

    it 'admin can access their projects' do
      expect(admin.accessible_projects).to include(project1)
      expect(admin.accessible_projects).not_to include(project2)
    end

    it 'regular user can access their projects' do
      expect(regular_user.accessible_projects).to include(project1)
      expect(regular_user.accessible_projects).not_to include(project2)
    end
  end
end
