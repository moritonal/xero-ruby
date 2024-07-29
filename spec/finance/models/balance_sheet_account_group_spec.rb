=begin
#Xero Finance API

#The Finance API is a collection of endpoints which customers can use in the course of a loan application, which may assist lenders to gain the confidence they need to provide capital.

Contact: api@xero.com
Generated by: https://openapi-generator.tech
OpenAPI Generator version: 4.3.1

=end

require 'spec_helper'
require 'json'
require 'date'

# Unit tests for XeroRuby::Finance::BalanceSheetAccountGroup
# Automatically generated by openapi-generator (https://openapi-generator.tech)
# Please update as you see appropriate
describe 'BalanceSheetAccountGroup' do
  before do
    # run before each test
    @instance = XeroRuby::Finance::BalanceSheetAccountGroup.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of BalanceSheetAccountGroup' do
    it 'should create an instance of BalanceSheetAccountGroup' do
      expect(@instance).to be_instance_of(XeroRuby::Finance::BalanceSheetAccountGroup)
    end
  end
  describe 'test attribute "account_types"' do
    it 'should work' do
      # assertion here. ref: https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
    end
  end

  describe 'test attribute "total"' do
    it 'should work' do
      # assertion here. ref: https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
    end
  end

end
