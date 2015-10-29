# To change this template, choose Tools | Templates
# and open the template in the editor.

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib', 'engine')

require 'test/unit'
require 'file_definitions'

class File_definitions < Test::Unit::TestCase

  def setup
  end

  def test_fields_string
    klass = Object.const_set('B', Class.new)

    klass.module_eval do
      include FileDefinitions
      create_field_definition 'a_string'

      create_field_attr_accessors
    end

    x = B.new '33'
    assert_equal '33', x.a_string

  end

  def test_fields_symbols
    klass = Object.const_set('SymClass', Class.new)
    klass.module_eval do
      include FileDefinitions
      create_field_definition [:a_symbol, :b_symbol]

      create_field_attr_accessors
    end

    assert SymClass.new.respond_to? :a_symbol
    assert SymClass.new.respond_to? :b_symbol
  end

  def test_fields_strings
    klass = Object.const_set('A', Class.new)
    klass.module_eval do
      include FileDefinitions
      create_field_definition %w(abc def  ghi jkl)

      create_field_attr_accessors
    end

    x = A.new

    assert_equal %w(abc def ghi jkl), A.field_definition.sort

    A.add_field( 'xyz' )

    line = '1,2,3,4, 5'
    x = A.new(line)

    assert x.respond_to? 'abc'
    assert x.respond_to? 'abc='
    assert x.respond_to? :jkl
    assert_equal x.current_line, line
    assert_equal '1', x.abc
    assert_equal 1.0, x.abc.to_f
    assert_equal 1,   x.abc.to_i
    assert_equal '4', x.jkl
    assert_equal ' 5', x.xyz

  end

  def test_fixed_strings

    klass = Object.const_set('AFixed', Class.new)

    klass.module_eval do
      include FileDefinitions

      create_fixed_definition( 'value' => (0..7), 'date' => (8..15), :ccy => (16..18) )

      create_field_attr_accessors
    end

    assert AFixed.respond_to?('fixed_definition')
    assert AFixed.respond_to?('field_definition')
    assert AFixed.respond_to?('add_field')
    assert AFixed.respond_to?('file_set_field_by_map')
    assert AFixed.respond_to?('split_on')
    assert AFixed.respond_to?('split_on_write')

    x = AFixed.new('0123456719990113EUR')

    assert x.respond_to?('value')
    assert x.respond_to?(:date)
    assert x.respond_to?('ccy')

    assert AFixed.field_definition.include?('ccy')

    assert_equal 3,  AFixed.field_definition.size
    assert_equal 3,  AFixed.fixed_definition.keys.size

    assert_equal %w(ccy date value), AFixed.field_definition.sort

    assert_equal AFixed.field_definition.sort, AFixed.fixed_definition.keys.sort

    assert_instance_of Range, AFixed.fixed_definition.values[0]

    assert_equal x.current_line, '0123456719990113EUR'
    assert_equal x.value, '01234567'
    assert_equal x.date, '19990113'
    assert_equal x.ccy, 'EUR'

    assert x.respond_to?(:parse)

    x.parse('9876543220100630USD')

    assert_equal x.current_line, '9876543220100630USD'
    assert_equal x.value, '98765432'
    assert_equal x.date, '20100630'
    assert_equal x.ccy, 'USD'

  end

  def test_bad_setup
    klass = Object.const_set('ABadClass', Class.new)
    begin
      klass.module_eval do
        include FileDefinitions

        create_fixed_definition( 'abc' )

        create_field_attr_accessors
      end
      flunk # We should never get here
    rescue => e
      assert e
    end
  end
end
