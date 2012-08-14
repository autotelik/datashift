##  DataShift 

Provides tools to shift data between Ruby, external applications, files and ActiveRecord.

Specific loaders and command line tasks for Spree E-Commerce.

Wiki taking shape with more info here : **https://github.com/autotelik/datashift/wiki**

### Features

Import and Export ActiveRecord models through .xls or CSV  files, including
all associations and setting configurable defaults or over rides.

Generate a sample template with headers only.

Export template and populate with model data 

Create, parse and use Excel/OpenOffice (.xls) documents dynamically from Ruby.

Easily extendable Loader functionality to deal with non trivial import cases, such
as complex association lookups.

High level rake and thor command line tasks for import/export provided.

Specific loaders and command line tasks provided out the box for **Spree E-Commerce**, 
enabling import/export of Product data including creating Variants with different
 count on hands and all associations including Properties/Taxons/OptionTypes and Images.

Loaders can be configured via YAML with over ride values, default values and mandatory column settings.

Many example Spreadsheets/CSV files in spec/fixtures, fully documented with comments for each column.

## Installation

Add gem 'datashift' to your Gemfile/bundle, or install the latest gem as usual :

    gem install datashift

To use :

    gem 'datashift'
    require 'datashift'

To pull the tasks in, add this call to your Rakefile :

<<<<<<< HEAD
```ruby 
    DataShift::load_tasks
```

To keep the availability to only development mode use

```ruby 
    DataShift::load_tasks if(Rails.env.development?)
```
=======
```ruby DataShift::load_tasks```

To keep the availability to only development mode use

```ruby DataShift::load_tasks if(Rails.env.development?)```
>>>>>>> a6d5d492fd9df38a4acb8c50423219994b4b5601

To use the Thor command line applications :

    Create a high level .thor file - e.g mysite.thor - in your applications root directory 

Edit the file and add the following to pull in the thor commands :
```ruby
    require 'thor'
    require 'datashift'

    DataShift::load_commands
```
To check the available tasks run

    bundle exec rake -T datashift

and/or

    bundle exc thor list datashift

To get usage information use thor help <command>, for example

    bundle exec thor help datashift:generate:excel

N.B - To use the Excel loader, OLE and Excel are NOT required, however
JRuby is required, since it uses Java's Apache POI under the hood to process .xls files.

Guards are provided, and used internally, for mixed Ruby setups. Can be used like :

    if(DataShift::Guards::jruby? )
        ..do something with Excel
    else
        ..do something with CSV
    end

## Active Record - Import/Export

Provides high level rake tasks for importing data via ActiveRecord models into a DB,
 from various sources, currently csv or .xls files (Excel/Open Office)

N.B This is under active development, moving to thor tasks so maybe out of date

Please try rake -T and  thor list to get upto date command lines

    bundle exec rake datashift:import:csv model=BlogPost input=BlogPostImport.csv verbose=true 

    jruby -S rake datashift:import:excel model=BlogPost input=BlogPostImport.xls verbose=true 

Provides high level rake tasks for exporting data to various sources, currently .xls files (Excel/Open Office)

    jruby -S rake datashift:export:excel model=BlogPost result=BlogExport.xls 


The library can be easily extended with Loaders to deal with non trivial cases,
 for example when multiple lookups required to find right association.

Spree loaders are an example, these illustrate over riding processing for specific columns with
complicated lookup requirements. Spree is the prime Open Source e-commerce project for Rails, 
and the specific loaders and tasks support loading Spree Products, and associated data such as Variants,
OptionTypes, Properties and Images.

## Template Generation and Export

Template generation tasks can be used to export a model's definition as column headings to CSV or .xls.
These can be provided to developers or business users, as a template for data collection and then loading.

Export tasks can be used to export of a model's definition and any existing data stored in the database.

This data can be exported directly to CSV or Excel/OpenOffice spreadsheets.


## Example Spreadsheets
    
  A number of example Spreadsheets with headers and comments, can be found in the spec/fixtures directory.

  Extensive Spree samples - including .xls and csv versions for simple Products or complex Products with multiple
  taxons, variants properties etc - can be found in the spec/fixtures/spree subdirectory.

  Column headings contain comments with full descriptions and instructions on syntax. 


## Features

- *High level wrappers around applications including Excel and Word

  Quickly and easily access common enterprise applications through Ruby

  Wrapper around MS Excel File format, acheived via Apache POI under JRuby, so not restricted to Windows
  and Excel does not need to be installed.

  The required POI jars are already included.

- *Direct Excel export*

  Excel/OpenOffice spreadsheets are heavily used in many sectors, so direct support makes it
  easier and quicker to migrate your client's data into a Rails/ActiveRecord project.

  No need to save to CSV or map to YAML.
  
- *Semi-Smart Name Lookup*

  Includes helper classes that find and store details of all possible associations on an AR class.
  Given a user supplied name, attempts to find the requested association.

  Example usage, load from a file or spreadsheet where the column names are only
  an approximation of the actual associations, so given 'Product Properties' heading,
  finds real association 'product_properties' to send or call on the AR object

- *Associations*

  Can handle 'belongs_to, 'has_many' and 'has_one' associations, including assignment of multiple objects
  via either multiple columns, or via specially delimited entry in a single (column). See Details section.

  Supports delegated attributes.

- *Rake Tasks*

  High level Rake tasks are provided, only required to supply model class, and file location :

    jruby -S rake datashift:import:excel model=MusicTrack input=MyTrackListing.xls


- *Spree Rake Tasks*

  Spree's product associations are non trivial so specific Rake tasks are also provided for loading Spree Producta
  with all associations and Image loading.

    jruby -S rake datashift:spree:products input=C:\MyProducts.xls


- *Seamless Spree Image loading can be achieved by ensuring SKU or class Name features in Image filename.

  Lookup is performed either via the SKU being prepended to the image name, or by the image name being equal to the **name attribute** of the klass in question.

  Images can be attached to any class defined with a suitable association. The class to use can be configured in rake task via
  parameter klass=Xyz.

  In the Spree tasks, this defaults to Product, so attempts to attach Image to a Product via Product SKU or Name.
 
  Image loading **does not** specifically require JRuby

  A report is generated in the current working directory detailing any Images in the paths that could not be matched with a Product.

  rake  datashift:spree:images input=C:\images\product_images skip_if_no_assoc=true

  rake  datashift:spree:images input=C:\images\taxon_icons skip_if_no_assoc=true klass=Taxon

## Import to Active Record

### Associations

To perform a lookup for an associated model, the primary column(s) must be supplied, along with required select values for those columns.

A single association column can contain multiple name/value sets, in string form :

  column:lookup_key_1, lookup_key_2,...

So if our Project model has many Categories, we can supply a Category list, which is keyed on the column Category.reference with :

  |Categories|

  reference:category_001,category_002

During loading, a call to find_all_by_reference will be made, picking up the 2 categories with matching references,
 and our Project model will contain those two i.e project.categories = [category_002,category_003]


## TODO

  - Add direct Image loading to Spree  i.e should be able to specify just path in a column .. "/images/red-tshirt.jpg"

  - Smart sorting of column processing order ....

  - Does not currently ensure mandatory columns (for valid?) processed first.

  - Look at implementing import/export API using something like https://github.com/ianwhite/orm_adapter 
    rather than active record, so we can support additional ORMs

  - Create separate Spree extension to support import/export via the admin gui
    
## License

Copyright:: (c) Autotelik Media Ltd 2011

Author ::   Tom Statter

Date ::     Dec 2011

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