# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie

    @gems_to_skip = ['actionmailer', 'actionpack', 'activemodel', 'activeresource', 'activesupport',
                     'bundler',
                     'mail',
                     'mysql2',
                     'rails',
                     'tzinfo' # HUGE!
    ]

    def self.gems_to_skip
      @gems_to_skip
    end

    initializer "simple_worker.configure_rails_initialization" do |app|
      SimpleWorker.logger.info "Initializing SimpleWorker for Rails 3..."
      start_time = Time.now
      SimpleWorker.configure do |c2|
        models_path = File.join(Rails.root, 'app/models/*.rb')
        c2.models = Dir.glob(models_path)
        mailers_path = File.join(Rails.root, 'app/mailers/*.rb')
        c2.mailers = Dir.glob(mailers_path).collect { |m| {:filename=>m, :name => File.basename(m), :path_to_templates=>File.join(Rails.root, "app/views/#{File.basename(m, File.extname(m))}")} }
        c2.extra_requires += ['active_support/core_ext', 'action_mailer']
        #puts 'DB FILE=' + File.join(Rails.root, 'config', 'database.yml').to_s
        if defined?(ActiveRecord) && File.exist?(File.join(Rails.root, 'config', 'database.yml'))
          c2.extra_requires += ['active_record']
          c2.database = Rails.configuration.database_configuration[Rails.env]
        else
          #puts 'NOT DOING ACTIVERECORD'
        end
        c2.gems = get_required_gems if defined?(Bundler)
        SimpleWorker.logger.debug "MODELS " + c2.models.inspect
        SimpleWorker.logger.debug "MAILERS " + c2.mailers.inspect
        SimpleWorker.logger.debug "DATABASE " + c2.database.inspect
        SimpleWorker.logger.debug "GEMS " + c2.gems.inspect
      end
      end_time = Time.now
      SimpleWorker.logger.info "SimpleWorker initialized. Duration: #{((end_time.to_f-start_time.to_f) * 1000.0).to_i} ms"

    end

    def get_required_gems
      gems_in_gemfile = Bundler.environment.dependencies.select { |d| d.groups.include?(:default) }
      SimpleWorker.logger.debug  'gems in gemfile=' + gems_in_gemfile.inspect
      gems =[]
      specs = Bundler.load.specs
      SimpleWorker.logger.debug 'Bundler specs=' + specs.inspect
      SimpleWorker.logger.debug "gems_to_skip=" + self.class.gems_to_skip.inspect
      specs.each do |spec|
        SimpleWorker.logger.debug 'spec.name=' + spec.name.inspect
        SimpleWorker.logger.debug 'spec=' + spec.inspect
        if self.class.gems_to_skip.include?(spec.name)
          SimpleWorker.logger.debug "Skipping #{spec.name}"
          next
        end
#        next if dep.name=='rails' #monkey patch
        gem_info = {:name=>spec.name, :version=>spec.version}
        gem_info[:auto_merged] = true
# Now find dependency in gemfile in case user set the require
        dep = gems_in_gemfile.find { |g| g.name == gem_info[:name] }
        if dep
          SimpleWorker.logger.debug  'dep found in gemfile: ' + dep.inspect
          SimpleWorker.logger.debug 'autorequire=' + dep.autorequire.inspect
          gem_info[:require] = dep.autorequire if dep.autorequire
#        spec = specs.find { |g| g.name==gem_info[:name] }
        end
        gem_info[:version] = spec.version.to_s
        gems << gem_info
        path = SimpleWorker::Service.get_gem_path(gem_info)
        if path
          gem_info[:path] = path
          if gem_info[:require].nil? && dep
            # see if we should try to require this in our worker
            require_path = gem_info[:path] + "/lib/#{gem_info[:name]}.rb"
            SimpleWorker.logger.debug  "require_path=" + require_path
            if File.exists?(require_path)
              SimpleWorker.logger.debug  "File exists for require"
              gem_info[:require] = gem_info[:name]
            else
              SimpleWorker.logger.debug  "no require"
#              gem_info[:no_require] = true
            end
          end
        end
#        else
#          SimpleWorker.logger.warn "Could not find gem spec for #{gem_info[:name]}"
#          raise "Could not find gem spec for #{gem_info[:name]}"
#        end
      end
      gems
    end

  end
end
