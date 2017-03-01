## DataShift

Datashift is a suite of tools to help you import or export data from a Rails application.

Formats currently supported are Excel, CSV files and Paperclip attachments.

Use CSV or Excel/OpenOffice/LibraOffice etc (.xls) files to Import or Export your database (ActiveRecord) models

Bulk import tools for Paperclip attachments from filesystem.

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

Import and Export direct to Excel (.xls) files.

Bulk upload [Paperclip](https://github.com/thoughtbot/paperclip)  supported filetypes from the filesystem,
such as images, documents.
 
Uploaded assets can be auto-attached to associated instances of the parent model.

For example bulk uploading product images to attach them to existing Products.

Smart import - Datashift will try its best to automatically map the headers in your import data to 
your ActiveRecord model **attributes** and **associations**

Easy to configure and map columns to your database when automatic mapping doesn't quite cut it.

Provides CLI tools to generate these configuration and mapping documents, to aid quickly
mapping your data to the destination target. 

Easily Apply different Data transformations during import or export.

* Defaults - Where your column is empty, provide a default value to be used.

* Overrides - When you want to provide a set value in all cases, or when you have no inbound data.

* Prefixes/Postfixes - Amend data on the fly. e.g if you wish to prepend a string id to a reference type field.

There are specific import/export loaders for [Spree E-Commerce](http://spreecommerce.com/) here @ [datashift_spree](https://github.com/autotelik/datashift_spree "Datashift Spree")


Bulk import tools from filesystem, for Paperclip attachments, takes folder of attachments such as images/mp3s/files
and use the file name to find and attach to DB models. For example look up a product, by it's '''SKU''',
based on the **SKU being present the image filename**, and attache that image to the product's '''images''' association

Export association data inline, in either hash or json formats, covering all association types.

Association types to include/exclude can be set in configuration as well as speciifc columsn to exclude.

Rails standard columns such as id, created_at etc can also be easily excluded via Configuration.

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

Set default values, substitutions and transformations per column for Imports.

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
      

#### <a name="ImportCLI">Active Record - Import CLI</a>

Please use thor list and thor help <xxx> to get latest command lines, for example

'''ruby
bundle exec thor datashift:import:csv --model BlogPost --input BlogPostImport.csv
'''

Imports are based on column headings with *Semi-Smart Name Lookup*

  On import, a dictionary of all possible attributes and associations is created for the AR class.
  
  This enables lookup, of a user supplied name (column heading), managing white space, pluralisation etc .

  Example usage, load from a file or spreadsheet where the column names are only
  an approximation of the actual associations, so given 'Product Properties' heading,
  finds real association 'product_properties' to send or call on the AR object

Can import 'belongs_to, 'has_many' and 'has_one' associations, including assignment of multiple objects
via either multiple columns, or via single column containing multiple entries in json/HASH format.

See Wiki for more details on DSL syntax.

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
