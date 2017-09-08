## DataShift

Datashift is a suite of tools to help you import or export data from a Rails application,
including all associations, in either hash or json formats.

Formats currently supported are Excel, CSV files and Paperclip attachments.

Use CSV or Excel/OpenOffice/LibraOffice etc (.xls) files to Import or Export your database (ActiveRecord) models

Bulk import tools for Paperclip to attach uploads (attachments) to model instances, from filesystem.

Comprehensive Wiki here : **<https://github.com/autotelik/datashift/wiki>**

[![Build Status](https://travis-ci.org/autotelik/datashift.svg?branch=master)](https://travis-ci.org/autotelik/datashift)
[![Code Climate](https://codeclimate.com/github/autotelik/datashift/badges/gpa.svg)](https://codeclimate.com/github/autotelik/datashift)
[![Test Coverage](https://codeclimate.com/github/autotelik/datashift/badges/coverage.svg)](https://codeclimate.com/github/autotelik/datashift/coverage)

- [Installation](#Installation)
- [Introduction](#Introduction)
- [CLI](#cli)
- [Features](#features)
- [Testing](#testing)
- [License](#license)


### <a name="Installation">Installation</a>

Add gem 'datashift' to your Gemfile/bundle or use ```gem install```

```ruby
gem 'datashift'
```
Win OLE and MS Excel are NOT required to use the Excel functionality.

### <a name="CLI">CLI</a>

High level applications are provided through command line tasks.

The API is available throughout your app.

To use the Thor command line applications, pull in the tasks.

Create or add to a high level .thor file in your lib/tasks or root directory

    e.g mysite.thor

Edit the file and add the following to pull in the datashift thor commands :

```ruby
    require 'thor'
    require 'datashift'

    DataShift::load_commands
```

To keep the availability to only development mode use

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

It's simple to use in standard Ruby, for example

```ruby
    DataShift::CsvLoader.new.run('db/seeds/permit.csv', PermitModel)

    DataShift::ExcelExporter.new.export('/tmp/mp3_dump.xls', MP3.where(style: 'banging techno').all)
```

#### <a name="Features">Features</a>

Import and Export direct to Excel (.xls) or CSV files.

Bulk upload [Paperclip](https://github.com/thoughtbot/paperclip) supported filetypes,
 from the filesystem, such as images, documents, mp3s, files.

Auto attach the Uploaded assets to associated instances of the parent model,
using the file name to find and attach to DB models. For example :

 - Looks up a product by it's '''SKU''', which **is present in the image filename** - my_sku_2017.jpg
 - Uploads the image
 - Attaches new image to the `my_sku_2017` product's '''images''' association

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

#### <a name="ImportCLI">Active Record - Import/Export CLI</a>

Please use `thor list` and thor help <cli>` to get latest command lines

'''ruby
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
'''

Exports are based around a single main DB model is supplied. Column headings will simply
reflect the database columns names and association names, although this is configurable.

A mapping configuration can be sued for both imports and exports to explicitly map
between headers and database names, when automatic generation not suitable.
 
On Import, a main DB model is supplied, for which a dictionary of all possible attributes
 and associations is created.
  
The Import is then based on column headings with *Semi-Smart Name Lookup*,
managing white space, pluralisation, under_scores etc.

So the user supplied name (column heading) need only be an approximation of the actual name,

For Example given column heading 'Product Properties' will still find real association 'product_properties'

#### <a name="Configuration">Configuration</a>

You can now configure datashift options with a typical initialisation block, for example

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
      



##### Paperclip

The loaded content is automatically attached to the model containing the `has_attached_file` directive.

Matching to this right attachment model instance, is performed using the filename.

The database field to match on, and the filename matching pattern are all configurable.


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

    A datashift **log **will be written within **spec/logs**, which hooks into the standard active record logger

          /log/datashift.log
          spec/logs/datashift_spec.log

## License

Copyright:: (c) Autotelik Media Ltd 2016

Author ::   Tom Statter

Date ::     April 2016

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
