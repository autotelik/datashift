## DataShift

[![Build Status](https://travis-ci.org/autotelik/datashift.svg?branch=master)](https://travis-ci.org/autotelik/datashift)
[![Code Climate](https://codeclimate.com/github/autotelik/datashift/badges/gpa.svg)](https://codeclimate.com/github/autotelik/datashift)
[![Test Coverage](https://codeclimate.com/github/autotelik/datashift/badges/coverage.svg)](https://codeclimate.com/github/autotelik/datashift/coverage)

Datashift is a suite of tools to help you import or export data from a Rails application,
including all associations, in either hash or json formats.

Formats currently supported are `.xls` files (Excel/OpenOffice/LibraOffice) and CSV files.

Paperclip bulk import tools for attaching uploads from filesystem, to Rails model instances.

[Wiki :](https://github.com/autotelik/datashift/wiki)

- [Installation](#Installation)
- [Features](#features)
- [Usage](#usage)
- [Import / Export](#ImportExport)
- [Testing](#testing)

### <a name="Installation">Installation</a>

Add gem 'datashift' to your Gemfile/bundle or use ```gem install```

```ruby
gem 'datashift'
```

#### <a name="Features">Features</a>

Import and Export direct to Excel (.xls) or CSV files.

Win OLE and MS Excel are NOT required to use the Excel functionality.

Bulk upload [Paperclip](https://github.com/thoughtbot/paperclip) supported filetypes,
 from the filesystem, such as images, documents, mp3s, files.

Auto attach the **uploaded** assets to associated instances of the parent model,
using the file name to find and attach to DB models. For example :

 - Upload the image to Rails storage
 - Looks up a product by it's '''SKU''', which **is present in the image filename** - my_sku_2017.jpg
 - Attaches new image to the Product `my_sku_2017` '''images''' association

Smart import - Datashift will try its best to automatically map the headers in your import data to 
your ActiveRecord model **attributes** and **associations**

Easy to configure and map columns to your database when automatic mapping doesn't quite cut it.

Fast mapping - Generate configuration and mapping documents automatically, to speed up mapping data to the destination target. 

Transform the data during import or export with defaults, substitutions etc.

There are specific import/export loaders for [Spree E-Commerce](http://spreecommerce.com/) here @ [datashift_spree](https://github.com/autotelik/datashift_spree "Datashift Spree")

Associations supported, with ability to define lookup column, and to find existing associated models 
to attach to the main Upload model,
 
Association types to include/exclude can be set in configuration as well as specific columns to exclude.

Rails standard columns such as id, created_at etc can be easily excluded via Configuration.

### <a name="Usage">Usage</a>

Multiple apps are provided through command line tasks via [Thor](https://github.com/erikhuda/thor).

To use the command line applications, pull in the tasks.

Create or add to a high level `.thor` file e.g mysite.thor in your `lib/tasks` or Rails root directory

Add the following lines, to pull in the datashift thor commands :

```ruby
    require 'thor'
    require 'datashift'

    DataShift::load_commands
```

To keep the availability to only development mode you can use

```ruby
DataShift::load_commands if(Rails.env.development?)
```

To check the available tasks run

```ruby
bundle exec thor list datashift
```

To get usage information use thor help <command>, for example

```ruby
bundle exec thor help datashift:generate:excel
```

#### <a name="ImportExport">Active Record - Import/Export CLI</a>

Please use `thor list` and thor help <cli>` to get latest command lines

```ruby
thor datashift:config:generate:import -m, --model=MODEL -r, --result=RESULT                                                                                                     ...
thor datashift:export:csv -m, --model=MODEL -r, --result=RESULT                                                                                                                 ...
thor datashift:export:db -p, --path=PATH                                                                                                                                        ...
thor datashift:export:excel -m, --model=MODEL -r, --result=RESULT                                                                                                               ...
thor datashift:generate:csv -m, --model=MODEL -r, --result=RESULT                                                                                                               ...
thor datashift:generate:db -p, --path=PATH                                                                                                                                      ...
thor datashift:generate:excel -m, --model=MODEL -r, --result=RESULT                                                                                                             ...
thor datashift:import:csv -i, --input=INPUT -m, --model=MODEL                                                                                                                   ...
thor datashift:import:excel -i, --input=INPUT -m, --model=MODEL                                                                                                                 ...
thor datashift:import:load -i, --input=INPUT -m, --model=MODEL 
````

Exports are currently based around a *single fundemental DB model* represented in a single Worksheet,
but can include all the associations of that model. 

Column headings will normally simply reflect the database columns names and association names, but this is configurable.

A mapping configuration can be used for both imports and exports, to explicitly map
between headers and database names, when automatic mapping not suitable.
 
On Import, a main DB model is supplied, for which a dictionary of all possible attributes
 and associations is created.
  
The Import is then based on column headings with *Semi-Smart Name Lookup*,
managing white space, pluralisation, under_scores etc.

So the user supplied name (column heading) need only be an approximation of the actual name.

For Example given column heading 'Product Properties', will still find real association 'product_properties'

#### <a name="Configuration">Configuration</a>

Configuration can be done either through a typical Rails initialisation code block,
 or a YAML configuration file provided at run time.

To create configurations, loaded during server start, use a typical initialisation block, for example

```ruby
DataShift::Configuration.call do |c|
  c.verbose = false
  c.remove_columns = [:milestones, :versions]
  c.remove_rails = true
  c.with = :all
end
 ```

See lib/datashift/configuration.rb for all the options

Imports/export can also be directed from YAML configuration file, to setup 
column mappings, transformations and custom methods for columns/data that require non trivial processing.
    
There is a generator, to create a skeleton configuration file template for you :

```ruby
thor help datashift:generate:config:import
```

##### Transformations

Transform the data during an import in various ways.

* Defaults - Where your column is empty, provide a default value to be used.

* Overrides - When you want to provide a set value in all cases, or when you have no inbound data.

* Prefixes/Postfixes - Amend data on the fly. e.g if you wish to prepend a string id to a reference type field.


```ruby
        DataShift::Transformation.factory do |factory|
          factory.set_default_on(Project, 'value_as_string',  'some default text' )
          factory.set_default_on(Project, 'value_as_double',   45.467 )
          factory.set_default_on(Project, 'value_as_boolean',  true )
          factory.set_default_on(Project, 'value_as_datetime', Time.now )
        end
```

  N.B The operator/column (2nd parameter) must match the inbound HEADER
 
  For example given a header **SKU**, for a class with real operator `sku=`, even though we know assignment will eventually
  use `sku=` this will not work :
       `factory.set_prefix_on(Spree::Product, 'sku', 'SPEC_')`
      
  
  But this will set the right prefix, because the header in the FILE is SKU 
      
      `factory.set_prefix_on(Spree::Product, 'SKU', 'SPEC_')`
   
##### Paperclip Import

Bulk upload from filesystem usign paperclip.
   
The general usage of paperclip is to define a model, which has associated attachments, for example
 
```ruby
   class Product < ActiveRecord::Base
     has_attached_file :image, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/images/:style/missing.png"
     validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
   end
```

Where datashift shines is when you want to bulk upload a hole load of images and attach
them to *existing* Products.
   
The loaded content is automatically attached to the model -  containing the `has_attached_file` directive - 
by matching the filename to a column of the model, in the case of our Product, perhaps the SKU or name.
   
The database field to match on, and the filename matching pattern are all configurable.

So in this example, to fix a set of products without images, the setup required would be :

- Create a directory of images, with the SKU of the product in the filename
- Configure datashift the upload with model Product and column matching on 'SKU' 
- Run `datashift:paperclip:attach --input /tmp/images --attach-to-klass Product --attach-to-find-by-field SKU --attachment-klass Image  --attach-to-field image` 
   
[See wiki](https://github.com/autotelik/datashift/wiki/Import-paperclip-facilities)

### <a name="API">General Ruby API</a>   

It's simple to use the facilites in standard Ruby, for example

```ruby
    DataShift::CsvLoader.new.run('db/seeds/permit.csv', PermitModel)


    records_for_export = MP3.where(style: 'banging techno').all
    DataShift::ExcelExporter.new.export('/tmp/mp3_dump.xls', records_for_export)
```

### <a name="Testing">Testing</a>

Specs need to run against a Rails sandbox app. 

A sandbox will be generated in `spec/dummy` if no such directory exists.
    
There are spec helpers to build the dummy app, via shelling out to `rails new`
 
The rails version used will be based on the latest you have installed, via the gemspec.
 
#### Changing Versions
 
To test different versions *update the gemspec* and run `bundle update rails`

    **N.B Manual Step**
    When changing versions you should **delete this whole directory**  `spec/dummy`
     
    Next time you run rspec it will auto generate a new dummy app using latest Rails versions

#### Run the Tests

    ** N.B You should run the specs from within the specs directory. **

```ruby
        bundle exec rspec -c .
```

 A datashift *log* will be written within **spec/logs**, which hooks into the standard active record logger


### Authors

    Thomas Statter - Initial idea and dev

Thanks to all [contributors](https://github.com/autotelik/datashift/contributors) who have participated in this project.

### License

Copyright:: (c) Autotelik Media Ltd 2016

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/autotelik/datashift/LICENSE.md) file for details
