# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
#
module RakeUtils

  # Method to check arguments from a rake task and display help if required
  #
  # Expects a block which prints out the usage information
  # 
  # task_args is expected to be of type Rake::TaskArguments
  #
  # NOTES: TaskArgs - bit of a weird class, has internal hash but also looks up on ENV
  #        So if ENV[:filter] defined, args[:filter] would return the value,
  #        but it would not show up in args.inspect or args.to_s or args.to_hash
  #
  def self.check_args( task_args, required = [] )

    # Tasks that call other tasks may wish to switch off displaying help for those sub tasks
    
    if( block_given? )
      yield unless task_args && required

      # Does task_args contain keys for ALL required items
      if(task_args[:help] || ENV['help'])
        yield
        exit(-1)
      end

      required.each do |r|
        unless(task_args.send(r))# || task_args[r.to_sym])
          puts "ERROR: Missing mandatory Param [#{r}]"
          yield
          exit(-1)
        end
      end
    end
  end

end
