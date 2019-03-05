#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do
 $running = false
end

while($running) do
 Blockchain.where(status: :active).each do |blockchain|
   blockchain.process_blockchain
 end
 sleep 5
end