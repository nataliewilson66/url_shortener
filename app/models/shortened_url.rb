class ShortenedUrl < ApplicationRecord
  validates :long_url, :short_url, :user_id, presence: true
  validates :short_url, uniqueness: true
  validate :no_spamming
  validate :nonpremium_max

  belongs_to :submitter,
    class_name: 'User',
    foreign_key: :user_id,
    primary_key: :id

  has_many :visits,
    class_name: 'Visit',
    foreign_key: :shortened_url_id,
    primary_key: :id

  has_many :visitors,
    -> { distinct },
    through: :visits,
    source: :visitor

  has_many :taggings,
    class_name: 'Tagging',
    foreign_key: :shortened_url_id,
    primary_key: :id

  has_many :tag_topics,
    through: :taggings,
    source: :topic

  def self.random_code
    string = SecureRandom.urlsafe_base64
    while self.exists?(:short_url => string)
      string = SecureRandom.urlsafe_base64
    end
    string
  end

  def self.create_for_user_and_long_url!(user, long_url)
    ShortenedUrl.create!(user_id: user.id, long_url: long_url, short_url: random_code)
  end

  def self.prune(n)
    ShortenedUrl.joins(:submitter)
                .joins('LEFT JOIN visits ON visits.shortened_url_id = shortened_urls.id')
                .where("(shortened_urls.id IN (
                    SELECT shortened_urls.id
                    FROM shortened_urls
                    JOIN visits ON visits.shortened_url_id = shortened_urls.id
                    GROUP BY shortened_urls.id
                    HAVING MAX(visits.created_at) < \'#{n.minutes.ago}\'
                    ) OR (
                    visits.id IS NULL AND shortened_urls.created_at < \'#{n.minutes.ago}\'
                    )) AND users.premium = \'f\' ")
                .destroy_all
  end

  def num_clicks
    Visit.select(:user_id)
         .where(shortened_url_id: self.id)
         .count
  end

  def num_uniques
    Visit.select(:user_id)
         .distinct
         .where(shortened_url_id: self.id)
         .count
  end

  def num_recent_uniques
    Visit.select(:user_id)
         .distinct
         .where(["shortened_url_id = ? and created_at >= ?", self.id, 10.minutes.ago])
         .count
  end

  private
  def no_spamming
    num_urls = ShortenedUrl.where(["user_id = ? and created_at >= ?", self.user_id, 1.minute.ago]).length
    if num_urls >= 5
      errors[:spam] << "can't submit more than 5 URLs in a single minute"
    end
  end

  def nonpremium_max
    return if User.find(self.user_id).premium

    num_urls = ShortenedUrl.where(user_id: self.user_id).length

    if num_urls >= 5
      errors[:nonpremium_max] << "non-premium users cannot submit more than 5 URLs"
    end
  end
end