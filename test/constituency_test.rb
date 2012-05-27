require 'minitest/autorun'
require 'mocha'

require_relative 'minitest_helper.rb'
require_relative '../models/constituency.rb'

class ConstituencyTest < MiniTest::Unit::TestCase
  def setup
    @lte = mock()
    @gte = mock()
    @exists = mock()
    @result = mock()
  end
  
  def test_exact_match_finder
    name = "Chesterfield"
    year = "1970"
    
    results = mock()
    results.stubs(:all).returns([])
    
    SymbolOperator.expects(:new).with(:year_created, 'lte').at_least(2).returns(@lte)
    SymbolOperator.expects(:new).with(:year_abolished, 'gte').returns(@gte)
    SymbolOperator.expects(:new).with(:year_abolished, 'exists').returns(@exists)
    
    Constituency.expects(:where).with({:name => /^#{name}$/i, @lte => year, @gte => year}).returns(results)
    Constituency.expects(:where).with({:name => /^#{name}$/i, @lte => year, @exists => false}).returns(results)
    
    assert_equal [], Constituency.find_exact_matches_by_year(name, year)
  end
  
  def test_fuzzy_match_finder
    name = "Chesterfield"
    year = "1970"
    
    results = mock()
    results.stubs(:all).returns([])
    
    SymbolOperator.expects(:new).with(:year_created, 'lte').at_least(2).returns(@lte)
    SymbolOperator.expects(:new).with(:year_abolished, 'gte').returns(@gte)
    SymbolOperator.expects(:new).with(:year_abolished, 'exists').returns(@exists)
    
    Constituency.expects(:where).with({:name => /#{name}/i, @lte => year, @gte => year}).returns(results)
    Constituency.expects(:where).with({:name => /#{name}/i, @lte => year, @exists => false}).returns(results)
    
    assert_equal [], Constituency.find_fuzzy_matches_by_year(name, year)
  end
  
  def test_find_constituency_with_exact_match
    Constituency.expects(:find_exact_matches_by_year).with("Chesterfield", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency("Chesterfield", 1970)
  end
  
  def test_find_constituency_with_fuzzy_match
    Constituency.expects(:find_exact_matches_by_year).with("chesterfield", 1970).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with("chesterfield", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency("chesterfield", 1970)
  end
  
  def test_colon_edge_case
    name = "Southwark: Bermondsey"
    Constituency.expects(:find_exact_matches_by_year).with("Southwark Bermondsey", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_comma_edge_case
    name = "Glasgow, Anniesland"
    
    Constituency.expects(:find_exact_matches_by_year).with(name, 2000).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with(name, 2000).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("Glasgow Anniesland", 2000).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 2000)
  end
  
  def test_bracket_edge_case
    name = "Richmond (Yorks)"
    Constituency.expects(:find_exact_matches_by_year).with('Richmond \(Yorks\)', 2000).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 2000)
  end
  
  def test_ampersand_edge_case_1
    name = "Penrith & The Border"
    Constituency.expects(:find_exact_matches_by_year).with("Penrith(?: and | & )The Border", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_ampersand_edge_case_2
    name = "Fermanagh and South Tyrone"
    Constituency.expects(:find_exact_matches_by_year).with("Fermanagh(?: and | & )South Tyrone", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_hyphen_edge_case_1
    name = "Newcastle upon Tyne Central"
    Constituency.expects(:find_exact_matches_by_year).with("Newcastle |-upon |-Tyne Central", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_hyphen_edge_case_2
    name = "Newcastle-under-Lyme"
    Constituency.expects(:find_exact_matches_by_year).with("Newcastle |-under |-Lyme", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_hyphen_edge_case_3
    name = "Chester le Street"
    Constituency.expects(:find_exact_matches_by_year).with("Chester |-le |-Street", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def text_bracket_edge_case
    name = "Ribble South (South Ribble)"
    
    Constituency.expects(:find_exact_matches_by_year).with(name, 2005).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with(name, 2005).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("Ribble South", 2005).returns([@result])
    
    assert_equal [@result], Constituency.find(name, 2005)
  end
  
  def test_name_south_vs_south_name
    name = "South East Staffordshire"
    
    Constituency.expects(:find_exact_matches_by_year).with(name, 1970).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with(name, 1970).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("Staffordshire South East", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_south_name_vs_name_south
    name = "Antrim South"
    
    Constituency.expects(:find_exact_matches_by_year).with(name, 1970).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with(name, 1970).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("South Antrim", 1970).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 1970)
  end
  
  def test_complex_heading_case_1
    name = "Dunfermline and Fife West"
    
    Constituency.expects(:find_exact_matches_by_year).with("Dunfermline(?: and | & )Fife West", 2005).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with("Dunfermline(?: and | & )Fife West", 2005).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("Dunfermline(?: and | & )West Fife", 2005).returns([@result])
    
    assert_equal [@result], Constituency.find_constituency(name, 2005)
  end
  
  def test_complex_heading_case_2
    name = "Basildon South and Thurrock East"
    #South Basildon and East Thurrock
    
    Constituency.expects(:find_exact_matches_by_year).with("Basildon South(?: and | & )Thurrock East", 2010).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with("Basildon South(?: and | & )Thurrock East", 2010).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("Basildon South(?: and | & )East Thurrock", 2010).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with("Basildon South(?: and | & )East Thurrock", 2010).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("South Basildon(?: and | & )Thurrock East", 2010).returns([])
    Constituency.expects(:find_fuzzy_matches_by_year).with("South Basildon(?: and | & )Thurrock East", 2010).returns([])
    Constituency.expects(:find_exact_matches_by_year).with("South Basildon(?: and | & )East Thurrock", 2010).returns([@result])    
    
    assert_equal [@result], Constituency.find_constituency(name, 2010)
  end
end