class Exercise < ActiveRecord::Base
  INDEXED_ATTRIBUTES = {
      against: [:title, :description],
      associated_against: {
          language: [:name],
          tags: [:name],
          guide: [:name]
      },
  }

  include WithSearch

  include WithMarkup
  include WithAuthor
  include WithSubmissions

  belongs_to :language
  belongs_to :guide

  has_many :expectations
  accepts_nested_attributes_for :expectations, reject_if: :all_blank, allow_destroy: true

  before_destroy :can_destroy?

  acts_as_taggable

  validates_presence_of :title, :description, :language, :test,
                        :submissions_count, :author, :locale
  after_initialize :defaults, if: :new_record?

  scope :by_tag, lambda { |tag| tagged_with(tag) if tag.present? }
  scope :at_locale, lambda { where(locale: I18n.locale) }

  markup_on :description
  markup_on :hint
  markup_on :teaser

  def self.create_or_update_for_import!(guide, original_id, options)
    exercise = find_or_initialize_by(original_id: original_id, guide_id: guide.id)
    exercise.assign_attributes(options)
    exercise.save!
  end

  def teaser(more_link)
    description.truncate(70, omission: more_link)
  end

  def status_for(user)
    s = submissions_for(user).last.try(&:status)
    case s
      when 'passed' then :passed
      when 'failed' then :failed
      else :unknown
    end
  end

  def can_destroy?
    can_edit? && submissions_count == 0
  end

  def can_edit?
    guide.nil?
  end

  def search_tags
    tag_list + [language.name] + (guide.try(&:name) || [])
  end

  def next_for(user)
    sibling_for user, 'exercises.original_id > :id', 'exercises.original_id asc'
  end

  def previous_for(user)
    sibling_for user, 'exercises.original_id < :id', 'exercises.original_id desc'
  end

  def sibling_for(user, query, order)
    guide.pending_exercises(user).where(query, id: original_id).order(order).first  if guide
  end

  private

  def defaults
    self.submissions_count = 0
  end
end
