# encoding: UTF-8
# frozen_string_literal: true
require 'yaml'

namespace :seed do
  
  desc 'Adds missing blockchains to database defined at config/seed/blockchains.yml.'
  task blockchains: :environment do  
    Blockchain.transaction do
      YAML.load_file(Rails.root.join('config/blockchains.yml')).each do |hash|
        next if Blockchain.exists?(key: hash.fetch('key'))
        Blockchain.create!(hash)
      end
    end
  end
end
