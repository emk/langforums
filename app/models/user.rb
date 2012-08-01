class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :public_name

  # Require a public name.
  validates :public_name, presence: true

  # Recently logged-in users.
  scope :recent, order(:last_sign_in_at).limit(10)

  # This is how users will be displayed in the forem UI.
  def to_s
    public_name
  end
end
