# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string           not null
#  role                   :integer          default("user"), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { user: 0, admin: 1, superadmin: 2 }

  has_many :user_projects, dependent: :destroy
  has_many :projects, through: :user_projects

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  scope :active, -> { where(deleted_at: nil) }

  def full_name
    name
  end

  def can_manage_projects?
    admin? || superadmin?
  end

  def can_manage_users?
    admin? || superadmin?
  end

  def can_manage_integrations?
    admin? || superadmin?
  end

  def accessible_projects
    if superadmin?
      Project.all
    elsif admin?
      projects
    else
      projects.where(user_projects: { role: %w[member admin] })
    end
  end
end
