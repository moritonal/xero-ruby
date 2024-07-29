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

# Unit tests for XeroRuby::Finance::ReportHistoryModel
# Automatically generated by openapi-generator (https://openapi-generator.tech)
# Please update as you see appropriate
describe 'ReportHistoryModel' do
  before do
    # run before each test
    @instance = XeroRuby::Finance::ReportHistoryModel.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of ReportHistoryModel' do
    it 'should create an instance of ReportHistoryModel' do
      expect(@instance).to be_instance_of(XeroRuby::Finance::ReportHistoryModel)
    end
  end
  describe 'test attribute "report_name"' do
    it 'should work' do
      # assertion here. ref: https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
    end
  end

  describe 'test attribute "report_date_text"' do
    it 'should work' do
      # assertion here. ref: https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
    end
  end

  describe 'test attribute "published_date_utc"' do
    it 'should work' do
      # assertion here. ref: https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
    end
  end

end
