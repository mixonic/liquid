require 'test_helper'

class ForTagTest < Test::Unit::TestCase
  include Liquid

  def test_for
    assert_template_result(' yo  yo  yo  yo ','{%for item in array%} yo {%endfor%}','array' => [1,2,3,4])
    assert_template_result('yoyo','{%for item in array%}yo{%endfor%}','array' => [1,2])
    assert_template_result(' yo ','{%for item in array%} yo {%endfor%}','array' => [1])
    assert_template_result('','{%for item in array%}{%endfor%}','array' => [1,2])
    expected = <<HERE

  yo

  yo

  yo

HERE
    template = <<HERE
{%for item in array%}
  yo
{%endfor%}
HERE
    assert_template_result(expected,template,'array' => [1,2,3])
  end

  def test_for_reversed
    assigns = {'array' => [ 1, 2, 3] }
    assert_template_result('321','{%for item in array reversed %}{{item}}{%endfor%}',assigns)
  end

  def test_for_with_range
    assert_template_result(' 1  2  3 ','{%for item in (1..3) %} {{item}} {%endfor%}')
  end

  def test_for_with_variable
    assert_template_result(' 1  2  3 ','{%for item in array%} {{item}} {%endfor%}','array' => [1,2,3])
    assert_template_result('123','{%for item in array%}{{item}}{%endfor%}','array' => [1,2,3])
    assert_template_result('123','{% for item in array %}{{item}}{% endfor %}','array' => [1,2,3])
    assert_template_result('abcd','{%for item in array%}{{item}}{%endfor%}','array' => ['a','b','c','d'])
    assert_template_result('a b c','{%for item in array%}{{item}}{%endfor%}','array' => ['a',' ','b',' ','c'])
    assert_template_result('abc','{%for item in array%}{{item}}{%endfor%}','array' => ['a','','b','','c'])
  end

  def test_for_helpers
    assigns = {'array' => [1,2,3] }
    assert_template_result(' 1/3  2/3  3/3 ',
                           '{%for item in array%} {{forloop.index}}/{{forloop.length}} {%endfor%}',
                           assigns)
    assert_template_result(' 1  2  3 ', '{%for item in array%} {{forloop.index}} {%endfor%}', assigns)
    assert_template_result(' 0  1  2 ', '{%for item in array%} {{forloop.index0}} {%endfor%}', assigns)
    assert_template_result(' 2  1  0 ', '{%for item in array%} {{forloop.rindex0}} {%endfor%}', assigns)
    assert_template_result(' 3  2  1 ', '{%for item in array%} {{forloop.rindex}} {%endfor%}', assigns)
    assert_template_result(' true  false  false ', '{%for item in array%} {{forloop.first}} {%endfor%}', assigns)
    assert_template_result(' false  false  true ', '{%for item in array%} {{forloop.last}} {%endfor%}', assigns)
  end

  def test_for_and_if
    assigns = {'array' => [1,2,3] }
    assert_template_result('+--',
                           '{%for item in array%}{% if forloop.first %}+{% else %}-{% endif %}{%endfor%}',
                           assigns)
  end

  def test_for_else
    assert_template_result('+++', '{%for item in array%}+{%else%}-{%endfor%}', 'array'=>[1,2,3])
    assert_template_result('-',   '{%for item in array%}+{%else%}-{%endfor%}', 'array'=>[])
    assert_template_result('-',   '{%for item in array%}+{%else%}-{%endfor%}', 'array'=>nil)
  end

  def test_sorting
    assigns = {'array' => [1,2,3,4,5,6,7,8,9,0]}
    assert_template_result('0123456789', '{%for i in array order:ascending %}{{ i }}{%endfor%}', assigns)
    assert_template_result('9876543210', '{%for i in array order:descending %}{{ i }}{%endfor%}', assigns)
    assert_template_result('765', '{%for i in array order:descending offset:2 limit:3 %}{{ i }}{%endfor%}', assigns)

    assigns = {'array' => [{"name" => 'A', "count" => '3'}, {"name" => 'C', "count" => '1'}, {"name" => 'B', "count" => '2'}]}
    assert_template_result('A|B|C|', '{%for i in array sort_by:name %}{{ i["name"] }}|{%endfor%}', assigns)
    assert_template_result('C|B|A|', '{%for i in array sort_by:name order:descending %}{{ i["name"] }}|{%endfor%}', assigns)
    assert_template_result('1|2|3|', '{%for i in array sort_by:count %}{{ i["count"] }}|{%endfor%}', assigns)
    assert_template_result('A|C|B|', '{%for i in array sort_by:missing_attribute %}{{ i["name"] }}|{%endfor%}', assigns)
  end

  def test_limiting
    assigns = {'array' => [1,2,3,4,5,6,7,8,9,0]}
    assert_template_result('12', '{%for i in array limit:2 %}{{ i }}{%endfor%}', assigns)
    assert_template_result('1234', '{%for i in array limit:4 %}{{ i }}{%endfor%}', assigns)
    assert_template_result('3456', '{%for i in array limit:4 offset:2 %}{{ i }}{%endfor%}', assigns)
    assert_template_result('3456', '{%for i in array limit: 4 offset: 2 %}{{ i }}{%endfor%}', assigns)
  end

  def test_dynamic_variable_limiting
    assigns = {'array' => [1,2,3,4,5,6,7,8,9,0]}
    assigns['limit'] = 2
    assigns['offset'] = 2

    assert_template_result('34', '{%for i in array limit: limit offset: offset %}{{ i }}{%endfor%}', assigns)
  end

  def test_nested_for
    assigns = {'array' => [[1,2],[3,4],[5,6]] }
    assert_template_result('123456', '{%for item in array%}{%for i in item%}{{ i }}{%endfor%}{%endfor%}', assigns)
  end

  def test_offset_only
    assigns = {'array' => [1,2,3,4,5,6,7,8,9,0]}
    assert_template_result('890', '{%for i in array offset:7 %}{{ i }}{%endfor%}', assigns)
  end

  def test_pause_resume
    assigns = {'array' => {'items' => [1,2,3,4,5,6,7,8,9,0]}}
    markup = <<-MKUP
      {%for i in array.items limit: 3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
      MKUP
    expected = <<-XPCTD
      123
      next
      456
      next
      789
      XPCTD
    assert_template_result(expected,markup,assigns)
  end

  def test_pause_resume_limit
    assigns = {'array' => {'items' => [1,2,3,4,5,6,7,8,9,0]}}
    markup = <<-MKUP
      {%for i in array.items limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:1 %}{{i}}{%endfor%}
      MKUP
    expected = <<-XPCTD
      123
      next
      456
      next
      7
      XPCTD
    assert_template_result(expected,markup,assigns)
  end

  def test_pause_resume_BIG_limit
    assigns = {'array' => {'items' => [1,2,3,4,5,6,7,8,9,0]}}
    markup = <<-MKUP
      {%for i in array.items limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:1000 %}{{i}}{%endfor%}
      MKUP
    expected = <<-XPCTD
      123
      next
      456
      next
      7890
      XPCTD
      assert_template_result(expected,markup,assigns)
  end


  def test_pause_resume_BIG_offset
    assigns = {'array' => {'items' => [1,2,3,4,5,6,7,8,9,0]}}
    markup = %q({%for i in array.items limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
      next
      {%for i in array.items offset:continue limit:3 offset:1000 %}{{i}}{%endfor%})
    expected = %q(123
      next
      456
      next
      )
      assert_template_result(expected,markup,assigns)
  end


  def test_for_tag_string
    # ruby 1.8.7 "String".each => Enumerator with single "String" element.
    # ruby 1.9.3 no longer supports .each on String though we mimic 
    # the functionality for backwards compatibility

    assert_template_result('test string', 
                '{%for val in string%}{{val}}{%endfor%}', 
                'string' => "test string")

    assert_template_result('test string', 
                '{%for val in string limit:1%}{{val}}{%endfor%}', 
                'string' => "test string")

    assert_template_result('val-string-1-1-0-1-0-true-true-test string', 
                '{%for val in string%}' + 
                '{{forloop.name}}-' + 
                '{{forloop.index}}-' + 
                '{{forloop.length}}-' + 
                '{{forloop.index0}}-' + 
                '{{forloop.rindex}}-' + 
                '{{forloop.rindex0}}-' + 
                '{{forloop.first}}-' + 
                '{{forloop.last}}-' + 
                '{{val}}{%endfor%}', 
                'string' => "test string")
  end

  def test_blank_string_not_iterable
    assert_template_result('', "{% for char in characters %}I WILL NOT BE OUTPUT{% endfor %}", 'characters' => '')
  end
end
