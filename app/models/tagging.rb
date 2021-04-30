class Tagging < ApplicationRecord
  validates :topic_id, :shortened_url_id, presence: true

  belongs_to :shortened_url,
    class_name: 'ShortenedUrl',
    foreign_key: :shortened_url_id,
    primary_key: :id

  belongs_to :topic,
    class_name: 'TagTopic',
    foreign_key: :topic_id,
    primary_key: :id

  def self.create_tag!(shortened_url, tag_topic)
    Tagging.create!(shortened_url_id: shortened_url.id, topic_id: tag_topic.id)
  end
end