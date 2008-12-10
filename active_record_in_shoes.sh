#!/usr/bin/env open -a Shoes.app
# 
# ActiveRecord In Shoes by tieg
# 8/13/2008

RAILS_ROOT = File.join('.', '..')
RAILS_ENV  = (ENV['RAILS_ENV'] || 'development').dup unless defined?(RAILS_ENV)

require "#{RAILS_ROOT}/config/environment"

module Navigation
  attr_accessor :content
  attr_accessor_with_default :model_stacks, {}
  
  def toggle_model_stack(model, offset=0)
    if model_stacks[model.to_s].contents.empty?
      load_model_stack(model, offset)
    else
      model_stacks[model.to_s].clear
    end
  end
  
  def load_model_stack(model, offset)
    model_stacks[model.to_s].clear do |stk|
      flow(:width => "20%")
      flow(:width => "10%") do
        button("<<") { load_model_stack(model, offset-1) } unless offset == 0
      end
      flow(:width => "70%") do
        button(">>") { load_model_stack(model, offset+1) } if model.count > offset+1
      end
      record = model.find(:first, :limit => 2,  :offset => offset)
      record.attributes.keys.sort.each do |key|
        value = record.attributes[key]
        flow(:width => "30%", :margin => 0, :height => 20) { para key, :size => 9, :weight => 'bold', :align => "right" }
        flow(:width => "70%", :margin => 0, :height => 20) { para value, :size => 9 }
      end
    end
  end
  
  def load_models_into_content
    content.clear do
      Dir.new(File.join(RAILS_ROOT, 'app', 'models')).select { |f| f =~ /\.rb$/ }.each do |file|
        model = file.gsub(/\.rb$/, '').camelize.constantize
        stack :width => "100%", :margin => [0,5] do
          background "#CCC"..."#FFF"
          flow :width => "75%" do
            para "#{model}", :align => "left", :size => 12, :margin => 10
            button("Toggle Browser", :size => 10, :margin => 5) { toggle_model_stack(model) }
          end
          para "#{model.count} records", :margin => 10
          model_stacks[model.to_s] = flow
        end if model.ancestors.include?(ActiveRecord::Base)
      end
    end
  end
end


Shoes.app :height => 700, :width => 600 do
  extend Navigation

  background "#D1EDF5"..."#FFF"
  stack :width => "100%" do
    para "ActiveRecord in Shoes ", link("reload", :size => 16) { load_models_into_content }, :size => 20, :margin => 10
  end

  self.content = stack :width => "100%"
  load_models_into_content
end
