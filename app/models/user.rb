# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ActiveRecord::Base
  
  has_secure_password
  has_many :microposts, dependent: :destroy #dependent: :destroy ensures that if any users are destroyed, so are the associated microposts
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy 

  #By default, in a has_many through association Rails looks for a foreign 
  #key corresponding to the singular version of the association; in other words, 
  #code like-> has_many :followeds, through: :relationships
  #would assemble an array using the followed_id in the relationships table. 
  #But, as noted in Section 11.1.1, user.followeds is rather awkward; far 
  #more natural is to use “followed users” as a plural of “followed”, and 
  #write instead user.followed_users for the array of followed users. Naturally, 
  #Rails allows us to override the default, in this case using the :source parameter 
  #(Listing 11.10), which explicitly tells Rails that the source of the followed_users 
  #array is the set of followed ids.
  has_many :followed_users, through: :relationships, source: :followed 
  
  # Note that we actually have to include the class name for this association, i.e.,
  # because otherwise Rails would look for a ReverseRelationship class, which doesn’t exist.
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
  
  # It’s also worth noting that we could actually omit the :source key in this case, using simply
  # since, in the case of a :followers attribute, Rails will singularize “followers” and 
  # automatically look for the foreign key follower_id in this case. I’ve kept the :source 
  # key to emphasize the parallel structure with the has_many :followed_users association, 
  # but you are free to leave it off.
  has_many :followers, through: :reverse_relationships, source: :follower 


  before_save { self.email = email.downcase }
  before_create :create_remember_token

  validates :name, presence: true, length: { maximum: 50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, 
  					format: { with: VALID_EMAIL_REGEX }, 
  					uniqueness: { case_sensitive: false }

  validates :password, presence: true, length: { minimum: 6}
  validates :password_confirmation, presence: true
  after_validation { self.errors.messages.delete(:password_digest) } # Removes "password digest can't be blank" error message

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    # Whether to include the explicit self is largely a matter of taste.
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy!
  end

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end
    
  

  private
    def create_remember_token
      self.remember_token = User.encrypt(User.new_remember_token)
    end
  
  


end
