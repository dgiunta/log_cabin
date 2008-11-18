# Developed by Chris Powers, Killswitch Collective on 11/18/2008
#
# The LogCabin class is designed to give you the flexibility to write 
# information about blocks of code and their execution times to 
# specific log files.
# 
# This is especially useful when monitoring and debugging a specific set
# of code in a model or controller file. For example:
# 
#   class UsersController < ApplicationController
#     def index
#       LogCabin.log_to :users_query do |log|
#         log.info "Finding all users with params = '#{params[:user_search].map{|k,v| "#{k}: #{v}"}.join(', ')}'"
#         @users = User.search(params[:user_search])
#         log.info "Found a total of #{@users.length} users"
#       end
#     end
#   end
# 
# This would print this out to /log/users_query.log
# 
#   INFO: Finding all users with params = 'last_name: Smith, city: Chicago'
#   INFO: Found a total of 32 users
#   TIME: Tue Nov 18 12:34:52 -0600 2008: Operation took 3.2876 seconds
# 
# It is also possible to pass an :if or :unless option to LogCabin#log_to, ex:
# 
#   LogCabin.log_to :users_query, :if => RAILS_ENV == 'development' do |log|
#     log.info "This will not output anything unless we're in development"
#     puts "But any other Ruby code ni this block will always be run"
#   end
# 
class LogCabin
  
  LOG_DIR = File.join(RAILS_ROOT, 'log')
  
  def initialize(log_name, options={})
    @file_path = file_path = File.join(LOG_DIR, log_name.to_s.gsub(/[^a-zA-Z0-9_\-]/, '') + '.log')
    @messages = []
    @options = options
  end
  
  def self.log_to(log_name, options={}, &block)
    logger = self.new(log_name, options)
    start = Time.now
    block.call(logger)
    stop = Time.now
    logger.write_log_with_duration(start, stop)
  end
  
  %w{info debug warn}.each do |method_name|
    define_method(method_name) do |message|
      log(method_name.to_s, message)
    end
  end
  
  def write_log_with_duration(start, stop)
    message = "#{start}: Operation took #{stop - start} seconds"
    log(:time, message)
    write_log
  end
  
  private
  
  def log(level, message)
    @messages << LogEntry.new(level.to_sym, message)
  end
  
  def write_log
    return unless should_log?
    File.open(@file_path, 'a') do |f|
      @messages.each {|m| f.puts m.print }
      f.puts "" # adds a newline between entries
    end
  end
  
  def should_log?
    if !@options[:if].nil?
      @options[:if] == true
    elsif !@options[:unless].nil?
      @options[:unless] == false
    else
      true
    end
  end
  
  
  class LogEntry
    def initialize(level, message)
      @level = level
      @message = message
    end
    
    def print
      "#{@level.to_s.upcase}: #{@message}"
    end
  end

end