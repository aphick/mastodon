# frozen_string_literal: true
# == Schema Information
#
# Table name: instances
#
#  domain         :string           primary key
#  accounts_count :bigint(8)
#

class Instance < ApplicationRecord
  self.primary_key = :domain

  attr_accessor :failure_days

  has_many :accounts, foreign_key: :domain, primary_key: :domain

  belongs_to :domain_block, foreign_key: :domain, primary_key: :domain
  belongs_to :domain_allow, foreign_key: :domain, primary_key: :domain
  belongs_to :unavailable_domain, foreign_key: :domain, primary_key: :domain # skipcq: RB-RL1031

  scope :matches_domain, ->(value) { where(arel_table[:domain].matches("%#{value}%")) }

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  def readonly?
    true
  end

  def delivery_failure_tracker
    @delivery_failure_tracker ||= DeliveryFailureTracker.new(domain)
  end

  def unavailable?
    unavailable_domain.present?
  end

  def purgeable?
    unavailable? || suspend? || !accounts.exists?
  end

  delegate :public_comment,
           :private_comment,
           :suspend?,
           to: :domain_block, allow_nil: true

  def to_param
    domain
  end
end
