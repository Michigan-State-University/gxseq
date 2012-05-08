### various class overrides for added functionality

## RUBY
##
# extend string class with to_formatted() method
begin
  class String
    def to_formatted(hsh={})
      per_row = hsh[:per_row] || 10
      rows = hsh[:rows] || 10
      delimiter = hsh[:delimiter] || "\n"
      match = hsh[:match] || "."
      num_char = rows*per_row+(rows-1)
      self.gsub(/((#{match}){#{per_row}})/,"\\1 ").gsub(/((#{match}|\s){#{num_char}})(\s)/,"\\1#{delimiter}")
    end
    def break_and_wrap_text(size=50,char="\n",ljust=0,justify_first=true)
      values=self.gsub(/(.{1,#{size}})( +|$)\n?|(.{1,#{size-1}})(,|;|:|-|=)|(.{#{size}})/,"\\1\\3\\4\\5\n").strip.split("\n")
      value=values.shift
      text=(justify_first ? char.ljust(ljust) : '')+"#{value.strip}"
      values.each do |v|
        text+=char.ljust(ljust)+"#{v.strip}"
      end
      return text
    end
  end
rescue
  puts "Error: could not extend the String class with to_formatted method"
  raise StandardError
end

# extend array class with sort_by method (sql-like)
begin
  class Array
    def sql_sort(method, order='ASC')
      return [] if self.empty?
      order = 'ASC' unless order.upcase == 'DESC'
      raise "Error: '#{self.first.class.name}'.'#{method}' undefined. Array.sort_by cannot continue" unless self.first.respond_to?(method)
      if(order =='ASC')
        return sort{|a,b| a.send(method)<=>b.send(method)}
      else
        return sort{|a,b| b.send(method)<=>a.send(method)}
      end
    end
  end
rescue
  puts "Error: could not extend the String class with to_formatted method"
  raise StandardError
end

## Bio-SQL
##
begin
  
  # extend method to return index as well as match
  module Bio::Sequence::Common
    def window_search(window_size, step_size = 1)
      last_step = 0
      0.step(self.length - window_size, step_size) do |i|
        yield(self[i, window_size],i)
        last_step = i
      end
      return self[last_step + window_size .. -1]
    end
  end
  
  ## Fix hard position parsing of locus line
  module Bio
    class GenBank::Locus
      def initialize(locus_line)
        if locus_line.empty?
          # do nothing (just for empty or incomplete entry string)
        else
          key,@entry_id,@length,length_t,@natype,@circular,@division,@date = locus_line.split("\s")
          @length = @length.to_i
        end
      end
    end
  end
rescue
  puts "Error: Bio Sequence definition in environment.rb failed\nDid you install the bio gem?\n#{$!}"
end

## ActiveRecord
##
module ActiveRecord
  class Base
    # fast_insert avoiding class instantiation. Skips validation, callbacks and observers
    def self.fast_insert(hsh)
      return false if hsh.empty?
      sql = "INSERT INTO #{table_name.upcase} (#{hsh.keys.map(&:to_s).join(", ")})
         VALUES('#{hsh.values.collect{|v|v.to_s.gsub(/\'/,"''")}.join("', '")}')"
      id = nil
      if(connection.prefetch_primary_key?(table_name))
          id = connection.next_sequence_value(sequence_name)
      end
      if (id)
        sql = sql.gsub(/INTO\s*#{table_name.upcase}\s*\(/,"INTO #{table_name.upcase} (#{primary_key.upcase},").gsub(/VALUES\s*\(/,"VALUES(#{id},")
      end
      return connection.insert(sql, "#{name} Create",primary_key, id, sequence_name)
    end
  end
end

# Fix for nested attributes mass assignment
# allows Composite Primary Key models within nested update
module ActiveRecord
  module NestedAttributes #:nodoc:
    def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
      options = nested_attributes_options[association_name]

      unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
        raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
      end

      if options[:limit] && attributes_collection.size > options[:limit]
        raise TooManyRecords, "Maximum #{options[:limit]} records are allowed. Got #{attributes_collection.size} records instead."
      end

      if attributes_collection.is_a? Hash
        keys = attributes_collection.keys
        attributes_collection = if keys.include?('id') || keys.include?(:id)
          Array.wrap(attributes_collection)
        else
          attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
        end
      end

      association = send(association_name)

      existing_records = if association.loaded?
        association.to_a
      else
        attribute_ids = attributes_collection.map {|a| a['id'] || a[:id] }.compact
        if((association.respond_to? :composite?) && association.composite?)
          # need to run lookup for individul Primary Keys. No Mass Finder for CPK
          attribute_ids.present? ? attribute_ids.collect{|att_id| association.find(att_id)} : []
        else
          attribute_ids.present? ? association.all(:conditions => {association.primary_key => attribute_ids}) : []
        end
      end
      
      attributes_collection.each do |attributes|
        attributes = attributes.with_indifferent_access

        if attributes['id'].blank?
          unless reject_new_record?(association_name, attributes)
            association.build(attributes.except(*UNASSIGNABLE_KEYS))
          end

        elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }
          association.send(:add_record_to_target_with_callbacks, existing_record) if !association.loaded? && !call_reject_if(association_name, attributes)
          assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])

        else
          raise_nested_attributes_record_not_found(association_name, attributes['id'])
        end
      end
    end
  end
end

## CompositePrimaryKeys
##

# Fix for PaperTrail Ver. 2.2.9 object.attributes.to_yaml. Force CompositeKey.to_yaml as string 'id1,id2'
class CompositePrimaryKeys::CompositeKeys
  def to_yaml 
    join(",")
  end
end

## PaperTrail
##

# extra order clause in has_paper_trail association 'order (self.primary_key)' causing errors. Removed
module PaperTrailFix
  def has_paper_trail(options={})
    super(options)
    has_many self.versions_association_name,
                     :class_name => version_class_name,
                     :as         => :item,
                     :order      => "created_at ASC"
   
  end
end

ActiveRecord::Base.class_eval do
  extend PaperTrailFix
end

# Extend devise method this would be easier (not necessary) with base devise_ldap_authenticatable but it doesn't support db_authenticatable
module Devise::LdapAdapter
  def self.get_ldap_param(login, param)
    options = build_ldap_options(login)
    resource = LdapConnect.new(options)
    resource.ldap_param_value(param)
  end  
  class LdapConnect
    def ldap_param_value(param)
      admin_ldap = LdapConnect.new(:admin => true).ldap
      unless bind(ldap)
        DeviseLdapAuthenticatable::Logger.send("Cannot bind to admin LDAP user")
        raise DeviseLdapAuthenticatable::LdapException, "Cannot connect to admin LDAP user"
      end
      user = find_ldap_user(admin_ldap)
      if(user[param].is_a?(Net::BER::BerIdentifiedArray))
        user[param].each do |ber|
          if(ber.is_a?(Net::BER::BerIdentifiedString))
            return ber
          end
        end
      end
      return nil
    end
  end
end

## Squeel
##
# fix Arel override causing LOB update failure. Probably from loss of column metadata?
module Arel
  class Table
    def [] name
      name = name.to_sym
      begin
        (columns.find { |column| column.name == name }) || (::Arel::Attribute.new self, name)
      rescue
        ::Arel::Attribute.new self, name
      end
      #old
      #::Arel::Attribute.new self, name.to_sym
    end
  end
end