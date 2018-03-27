## DataShift

[![Build Status](https://travis-ci.org/autotelik/datashift.svg?branch=master)](https://travis-ci.org/autotelik/datashift)
[![Code Climate](https://codeclimate.com/github/autotelik/datashift/badges/gpa.svg)](https://codeclimate.com/github/autotelik/datashift)
[![Test Coverage](https://codeclimate.com/github/autotelik/datashift/badges/coverage.svg)](https://codeclimate.com/github/autotelik/datashift/coverage)

Datashift is a suite of tools to help you import or export data from a Rails application,
including all association data.

Formats currently supported are `.xls` files (Excel/OpenOffice/LibraOffice) and CSV files.

It's not the fastest, but a key feature of the import is that unlike say a pure DB load,
inbound data is validated by your Rail's business logic, as defined by your validations, associations etc.

Paperclip bulk import tools for attaching uploads from filesystem, to Rails model instances.

##### Table of Contents

- [Installation](#Installation)
- [Features](#features)
- [Usage](#usage)
- [Import / Export](#ImportExport)
- [Associations](#Associations)
- [Testing](#testing)
- [Wiki](https://github.com/autotelik/datashift/wiki)

### <a name="Installation">Installation</a>

Add gem 'datashift' to your Gemfile

```ruby
gem 'datashift'
```
 
Direct install via usual ```gem install datashift```
 
There are also specific import/export loaders for [Spree E-Commerce](http://spreecommerce.com/) here @ [datashift_spree](https://github.com/autotelik/datashift_spree "Datashift Spree")

#### <a name="Features">Features</a>

* Import and Export direct to .xls files (Excel/OpenOffice etc) -  Win OLE and MS Excel are NOT required.

* Import and Export direct to CSV files.

* Bulk upload [Paperclip](https://github.com/thoughtbot/paperclip) supported filetypes,
 from the filesystem, such as images, documents, mp3s, files.

  - Auto attach the **uploaded** assets to associated instances of the parent model, using the file name to find and attach to DB models. For example :

        - Upload the image to Rails storage
        - Looks up a product by it's '''SKU''', which **is present in the image filename** - my_sku_2017.jpg
        - Attaches new image to the Product `my_sku_2017` '''images''' association

* Smart import - Datashift will try its best to automatically map the headers in your import data to 
your ActiveRecord model **attributes** and **associations**

* Easy to configure and map columns to your database when automatic mapping doesn't quite cut it.

* Fast mapping - Generate configuration and mapping documents automatically, to speed up mapping data to the destination target. 

* Transform the data during import or export with defaults, substitutions etc.

* Associations supported, with ability to define lookup column, and to find existing associated models 
to attach to the main Upload model,
 
* Association types to include/exclude can be set in configuration as well as specific columns to exclude.

* Easily exclude Rails standard columns such as id, created_at, updated_at etc.

### <a name="Usage">Usage</a>

#### <a name="API">General API</a>   

It's simple to use the facilities in standard Ruby, for example

```ruby
    DataShift::CsvLoader.new.run('db/seeds/permit.csv', PermitModel)


    music_to_export = MP3.where(style: 'banging techno').all
    
    DataShift::ExcelExporter.new.tap {|d| d.export('/tmp/mp3_dump.xls', music_to_export) }
```

In Rails, generally you would drive this via a Controller Action

For example
```ruby
class CategoriesController < ApplicationController

  def index
     @categories = Category.all
 
     respond_to do |format|
         format.xls do
              contents = StringIO.new
              DataShift::ExcelExporter.new.export(contents, @categories)
              send_data contents.string.force_encoding('binary'), type: 'application/xls'
         end
      end
```

> N.B You need to have registered the *xls* format as mime type, somewhere like `config/initializers/mime_types.rb`

```ruby
Mime::Type.register "application/xls", :xls
```

#### <a name="API">CLI</a>   


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

### <a name="ImportExport">Active Record - Import/Export CLI</a>

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

Exports are currently based around a *single fundamental DB model* represented in a single Worksheet,
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

### <a name="Associations">Associations</a>

Datashift can populate your main model's associations, searching for matching objects and assigning them to the load object.

To achieve this it supports a syntax within either column headings or individual cells to specify :

- Search Attribute - the field on the association model to search on.
- Search Value - the specific value(s) to attempt to find. 

So in the following example our main Project object has an has_many association with Category.

Category has a field called reference. We want to attach existing Categories to our newly created Project, based on values of this reference. 

##### Header or Cell based lookup

Specifying the lookup field in the column headings, our Excel (or CSV) file might look like this :

project name | *Categories:reference*
--- | ---
aphex | category_001
boc | category_003
autechre | category_001,category_002


> Note: Lookup can be specified at the individual cell level
        You can specify different lookup fields in different columns or cells.

project name | categories 
--- | --- 
aphex | *reference*:category_001,category_002
boc | *reference*:category_003
autechre | *reference*:category_001,category_002,category_003


##### Lookup Syntax

- `:` - Seperates lookup field name, here 'reference', from the values.
- `,` - Seperates *multiple* lookup values for has_many relationships


So in our example, datashift will perform searches like :

```ruby
Category.where("reference IN (?)", [category_001,category_002,category_003])
```

The resulting DB objects, will be assigned to the Project.categories

When specify has_many relationships multiple file columns can also be used. The following would lead to exactly the same end result, as the first example.


project name | categories  | categories 
--- | ---  | --- 
aphex | *reference*:category_001| *reference*:category_002
boc | *reference*:category_003| 
autechre | *reference*:category_001,category_002| *reference*:category_003



### <a name="Configuration">Configuration</a>

#### Global

Configuration of datashift can be done through a typical Rails initialisation code block,
 a YAML configuration file provided at run time, or both in which case run time options over ride global ones.

The easiest way to create a global configuration file, loaded during server start, 
is to run our rail's install generator : 

```ruby
rails g datashift:install
```

You can create a model specific file at anytime via
```bash
    thor datashift:config:generate:import
```
 
To create a Rails tyle config block manually, create an initialisation file within `config/initializers`, 
and see [lib/datashift/configuration.rb](lib/datashift/configuration.rb`) for details of all possible options, for example

```ruby
DataShift::Configuration.call do |c|
  c.verbose = false
  c.remove_columns = [:milestones, :versions]
  c.remove_rails = true
  c.with = :all
end
 ```

#### Export

You can use a YAML file or snippet to configure the column headers, and set of columns to include in an export

In this code based example, we only want 4 columns from our model.

DataFlowSchema is the class that represents a schema for the data flows, that is it directs an import or export.

We can use the `presentatio`n keyword to over ride rhe normal header (default is simply the column name).

```ruby
yaml= <<EOS
 data_flow_schema:
   MyRailsModelName:
     nodes:
       - id:
       - status_str:
           presentation: "Status Str"
       - user:
           presentation: "User Name"
       - status:
 EOS

         data_flow_schema = DataShift::DataFlowSchema.new.tap { |dfs| dfs.prepare_from_string(yaml) }
 
         DataShift::ExcelExporter.new.tap do |d|
           d.data_flow_schema = data_flow_schema
           d.export(File.join('tmp', 'conversion_for_removal.xls'), conversions)
         end
```

In this example we stored the YAML in memory, but you can also use a file, 
in which case the only change, is that the call to create a DataFlowSchema becomes : 
```ruby
  data_flow_schema = DataShift::DataFlowSchema.new.tap { |dfs| dfs.prepare_from_file(file_name) }
```


#### Mapping

Individual Imports/Export runs can also be directed from YAML configuration file.

This allows more fine grained control of the process, and can include column mappings instructions, 
data transformations and custom processing methods for columns/data that require non standard processing,
as well as global configuration parameters.
    
There is another generator, to create a skeleton configuration file, based on the model to be imported :

```ruby
thor help datashift:generate:config:import -m <MyModelToImport> -r config/datashift.rb
```

#### Transformations

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
   
#### Paperclip Import

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

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/autotelik/datashift/blob/master/LICENSE.md) file for details
