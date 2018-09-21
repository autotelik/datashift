# Use this hook to configure datashift processing

DataShift::Configuration.call do |config|

  # The List of association +TYPES+ to INCLUDE in processing based
  # on standard Rails association types :
  # [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
  #
  # config.with = [:assignment, :enum]

  # Configure what association types to ignore during export with associations.
  #
  # The default is to include ALL all association TYPES as defined by
  #   ModelMethod.supported_types_enum
  #
  # Supplied types will be filtered out, reducing the association types exported.
  #
  # config.exclude = [:belongs_to]

  # Configure the Global list of of columns to remove/ignore from files
  #
  # config.remove_columns = [:id, :dont_want_this, :no]

  # List of headers/columns that are Mandatory i.e must be present in the inbound data
  #
  # config.mandatory = [:yes]

  # Remove standard Rails cols like :id, created_at, updated_at
  # Default is false
  #
  # config.remove_rails = true

  # When performing import, default is to ignore any columns that cannot be mapped  (via headers)
  # To raise an error instead, set this to  true
  # Defaults to `false`.
  # config.strict_inbound_mapping

  # When performing writes use update methods that write immediately to DB
  # and use validations.
  #
  # Validations can ensure business logic, but can be less efficient as writes to DB once per column
  #
  # Default  is to use more efficient but less strict attribute writing - no write to DB/No validations run
  # config.update_and_validate

  # Controls the amount of information written to the log
  # Defaults to `false`. Set to `true` to cause extensive progress messages to be logged
  # config.verbose

  # Do everything except commit changes.
  # For import save will not be called on the final object
  # Defaults to `false`. Set to `true` to cause extensive progress messages to be logged
  # config.dummy_run

  # Expand association data into multiple columns
  #
  # config.expand_associations

  # When importing/exporting associations default is to include ALL associations of included TYPES
  #
  # Specify associations by name to remove
  #
  # config.exclude_associations

  #  List of external columns that do not map to any operator but should be included in processing.
  #
  #  Example use cases
  #
  #  Provides the opportunity for loaders to provide specific methods to handle columns
  #  that do not map directly to a model's operators or associations
  #
  #  Enable handling delegated methods i.e no direct association but method is on a model through it's delegate
  #
  # config.force_inclusion_of_columns

  #  All external columns should be included in processing whether or not they automatically map to an operator
  #
  # config.include_all_columns

  # Set a directory path to be used to prefix all inbound PATHs for image processing
  #
  # config.image_path_prefix

end
