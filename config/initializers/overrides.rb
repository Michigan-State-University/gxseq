### various class overrides for added functionality
begin
# CanCan
# Use include instead of Joins to avoid multiple records with inner joins
# https://github.com/ryanb/cancan/pull/726
class CanCan::ModelAdapters::ActiveRecordAdapter
  # override with new method
  def database_records
    if override_scope
      @model_class.scoped.merge(override_scope)
    elsif @model_class.respond_to?(:where) && @model_class.respond_to?(:joins)
      mergeable_conditions = @rules.select {|rule| rule.unmergeable? }.blank?
      if mergeable_conditions
        @model_class.where(conditions).includes(joins)
      else
        @model_class.where(*(@rules.map(&:conditions))).includes(joins)
      end
    else
      @model_class.scoped(:conditions => conditions, :joins => joins)
    end
  end
end

# Sunspot Index
  # avoid use of ':' in dynamic_field name
  module Sunspot
    class FieldFactory::Dynamic
      def build(dynamic_name)
        AttributeField.new("#{@name}_#{dynamic_name}", @type, @options.dup)
      end
      alias_method :field, :build
    end
    class Search::AbstractSearch
      def facet(name, dynamic_name = nil)
       if name
         if dynamic_name
           @facets_by_name[:"#{name}_#{dynamic_name}"]
         else
           @facets_by_name[name.to_sym]
         end
       end
      end
    end
    # Speed up adapter lookup ~ 25% speedup
    # https://github.com/sunspot/sunspot/issues/356
    class Adapters::InstanceAdapter
      def for(clazz)
        return ActiveRecordInstanceAdapter
      end
    end
  end
## RUBY
##
# extend string class with to_formatted() method
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
rescue => e
  puts "Error: could not extend the String class with to_formatted method"
  raise StandardError, "#{e}"
end

# extend array class with to_ranges for converting large arrays of similar integers to ranges.
begin
  class Array
    def to_ranges
      compact.sort.uniq.inject([]) do |r,x|
        (r.empty? || r.last.last.succ != x) ? r << (x..x) : r[0..-2] << (r.last.first..x)
      end
    end
  end
rescue
  puts "Error: could not extend the Array class with to_ranges method"
  raise StandardError
end

## DelayedJob
##
# add current_user to jobs and setup papertrail whodunnit
class Delayed::Backend::ActiveRecord::Job
  ## Setup the methods to save current_user into delayed_jobs
  before_create :set_user
  belongs_to :user
  def set_user
    self.user_id = self.class.whodunnit
  end
  # ripped from PaperTrail module
  # - Thread-safe hash to hold PaperTrail's data.
  def self.delayed_job_session_store
    Thread.current[:delayed_job] ||= {}
  end
  def self.whodunnit=(value)
    delayed_job_session_store[:user]=value
  end
  def self.whodunnit
    delayed_job_session_store[:user]
  end
  
  ## Setup papertrail whodunnit within background jobs - 'become' user for tracking
  def invoke_job
    PaperTrail.whodunnit = self.user_id
    super
  end
  
  ## Override the destroy function of jobs so we can keep them around
  def destroy(permanent=false)
    permanent ? super() : (self.completed_at = self.class.db_time_now; self.save)
  end
  # stop processing of completed jobs
  class << self
    def ready_to_run_with_completed_at(worker_name, max_run_time)
      ready_to_run_without_completed_at(worker_name, max_run_time).where('completed_at IS NULL')
    end
    alias_method_chain :ready_to_run, :completed_at
  end
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
  
  module Bio
    ## Fix hard position parsing of locus line
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
    ## Fix hard parsing of position line
    class GenBank
    def features
       unless @data['FEATURES']
         ary = []
         in_quote = false
         get('FEATURES').each_line do |line|
           next if line =~ /^FEATURES/

           # feature type  (source, CDS, ...)
           head = line[0,20].to_s.strip

           # feature value (position or /qualifier=)
           # Updated to grab the whole line instead of fixed position
           # ORIG: body = line[20,60].to_s.chomp
           body = line[20..-1].to_s.chomp
           # sub-array [ feature type, position, /q="data", ... ]
           if line =~ /^ {5}\S/
             ary.push([ head, body ])

           # feature qualifier start (/q="data..., /q="data...", /q=data, /q)
           elsif body =~ /^ \// and not in_quote		# gb:IRO125195
             ary.last.push(body)

             # flag for open quote (/q="data...)
             if body =~ /="/ and body !~ /"$/
               in_quote = true
             end

           # feature qualifier continued (...data..., ...data...")
           else
             ary.last.last << body

             # flag for closing quote (/q="data... lines  ...")
             if body =~ /"$/
               in_quote = false
             end
           end
         end

         ary.collect! do |subary|
           parse_qualifiers(subary)
         end

         @data['FEATURES'] = ary.extend(Bio::Features::BackwardCompatibility)
       end
       if block_given?
         @data['FEATURES'].each do |f|
           yield f
         end
       else
         @data['FEATURES']
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
  class Relation
    # overrides select with primary key only and returns results
    def select_ids
      join_dependency = construct_join_dependency_for_association_find
      relation = except(:select).select("#{@table.table_name}.#{@klass.primary_key}")
      @klass.connection.select_all(apply_join_dependency(relation, join_dependency).to_sql).collect{|row| row[@klass.primary_key]}
    rescue ThrowResult
      []
    end
    # returns closed interval ranges for primary keys
    def select_ranges
      if Base.connection.adapter_name.downcase =~ /.*oracle.*/
        join_dependency = construct_join_dependency_for_association_find
        relation = except(:select)
          .select("#{@table.table_name}.#{@klass.primary_key} as id,
            lag(#{@table.table_name}.#{@klass.primary_key}) over (order by #{@table.table_name}.#{@klass.primary_key}) as prev,
            lead(#{@table.table_name}.#{@klass.primary_key}) over (order by #{@table.table_name}.#{@klass.primary_key}) as next")
          .order("#{@table.table_name}.#{@klass.primary_key}")
          .group("#{@table.table_name}.#{@klass.primary_key}")
        rel_sql = apply_join_dependency(relation, join_dependency).to_sql
        low_sql = "Select id from (#{rel_sql}) where prev != (id-1) or prev is null order by id"
        high_sql = "Select id from (#{rel_sql}) where next != (id+1) or next is null order by id"
        lows = klass.connection.select_all(low_sql)
        highs = @klass.connection.select_all(high_sql)
        return_arr = []
        lows.each_with_index do |l,ind|
          return_arr << (l['id']..highs[ind]['id'])
        end
        return return_arr
      else
        select_ids.to_ranges
      end
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
## Streaming Support - fix
# TODO: Update to 3.1 and use new streaming support
# avoid double render/lookup in streaming actions
# http://stackoverflow.com/questions/3507594/ruby-on-rails-3-streaming-data-through-rails-to-client
class Rack::Response
  def close
    @body.close if @body.respond_to?(:close)
  end
end