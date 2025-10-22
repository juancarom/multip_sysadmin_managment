# == Schema Information
#
# Table name: projects
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :text
#  slug        :string           not null
#  active      :boolean          default(true), not null
#  settings    :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Project < ApplicationRecord
  has_many :user_projects, dependent: :destroy
  has_many :users, through: :user_projects
  has_many :integrations, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-_]+\z/ }
  validates :description, length: { maximum: 500 }

  before_validation :generate_slug, if: :name_changed?

  scope :active, -> { where(active: true) }

  def to_param
    slug
  end

  def admins
    users.joins(:user_projects).where(user_projects: { role: 'admin' })
  end

  def members
    users.joins(:user_projects).where(user_projects: { role: 'member' })
  end

  def active_integrations
    integrations.where(active: true)
  end

  def integration_by_type(integration_type)
    integrations.find_by(integration_type: integration_type)
  end

  private

  def generate_slug
    return if name.blank?

    base_slug = name.downcase.gsub(/[^a-z0-9\s\-_]/, '').gsub(/\s+/, '-')
    counter = 0
    self.slug = base_slug

    while Project.exists?(slug: slug) && slug != slug_was
      counter += 1
      self.slug = "#{base_slug}-#{counter}"
    end
  end
end
