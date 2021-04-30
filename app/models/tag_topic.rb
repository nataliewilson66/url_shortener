class TagTopic < ApplicationRecord
  validates :topic, presence: true
  validates :topic, uniqueness: true

  has_many :taggings,
    class_name: 'Tagging',
    foreign_key: :topic_id,
    primary_key: :id

  has_many :links,
    through: :taggings,
    source: :shortened_url

  def popular_links
    ShortenedUrl.joins(:visits)
                .group(:long_url, :short_url)
                .order('COUNT(visits.id) DESC')
                .select('long_url, short_url, COUNT(visits.id) as number_of_visits')
                .limit(5)
  end
end