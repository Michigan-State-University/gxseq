module ConsoleLogger
  module Model
    
    def self.included(base) #:nodoc:
      super
      base.extend(ClassMethods)
    end
    
    module ClassMethods      
      def has_console_log(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods
        has_one :console_log, :as => :loggable, :dependent => :destroy
      end
    end
    
    module InstanceMethods
      def web_console(options = {})
        #output a web_friendly view of the console
        width = options[:width] || 350
        height = options[:height] || 200
        color = options[:color] || 'rgb(50,92,147)'
        background = options[:background] || 'white'
        html = <<-HTML
          <div 
            style='
            height:#{height}px; 
            width:#{width}px; 
            padding:.5em;
            border:.5em lightgrey ridge;
            background:#{background};
            color:#{color};
            overflow:auto;'
          >
            <div style="width:#{self.console_log.console.split("\n").map(&:length).max}em">
            #{(self.console_log ? self.console_log.console.gsub(/\n/,"<br/>").gsub(/\t/,"&nbsp;&nbsp;&nbsp;&nbsp;") : "")}
            </div>
          </div>
        HTML
      end
      
      def log_puts(text)
        #store the text in our :text column
        if self.new_record?
          console_log || (build_console_log)
          old_text = console_log.console || ""
          console_log.console = (old_text + text)
        else
          console_log || (create_console_log;reload)
          old_text = console_log.console || ""
          console_log.update_attribute(:console, old_text + text)
        end
      end
      def puts(*args)
        #override the standard puts method to include persistent storage
        super(*args)
        log_text = ""
        args.each do |item|
          case item.class.name
          when 'Array'
            item.each do |member|
              log_text << member.to_s << "\n"
            end
          when 'String'
            log_text << item.to_s << "\n"
          end
        end
        log_text = "\n" if log_text.empty?
        log_puts(log_text)
      end
    end
    
  end
end

ActiveRecord::Base.send :include, ConsoleLogger::Model