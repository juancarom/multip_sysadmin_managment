# == Schema Information
#
# Table name: user_projects
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  project_id :bigint           not null
#  role       :integer          default("member"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class UserProject < ApplicationRecord
  belongs_to :user
  belongs_to :project

  enum role: { member: 0, admin: 1 }

  validates :user_id, uniqueness: { scope: :project_id }
  validates :role, presence: true

  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }

  # Callbacks for external integration sync
  after_create :sync_user_added_to_integrations
  after_destroy :sync_user_removed_from_integrations

  private

  def sync_user_added_to_integrations
    UserProjectSyncJob.perform_later(id, 'add')
  end

  def sync_user_removed_from_integrations
    UserProjectSyncJob.perform_later(id, 'remove')
  end
end
