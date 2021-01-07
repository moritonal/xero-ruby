=begin
#Accounting API

#No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)

The version of the OpenAPI document: 2.6.0
Contact: api@xero.com
Generated by: https://openapi-generator.tech
OpenAPI Generator version: 4.3.1

=end

require 'date'
require 'json'
require 'logger'
require 'tempfile'
require 'find'
require 'faraday'

module XeroRuby
  class ApiClient
    # The Configuration object holding settings to be used in the API client.
    attr_accessor :config

    # Defines the headers to be used in HTTP requests of all API calls by default.
    #
    # @return [Hash]
    attr_accessor :default_headers

    # Initializes the ApiClient
    # @option config [Configuration] Configuration for initializing the object, default to Configuration.default
    def initialize(config: Configuration.default, credentials: {})
      @client_id = credentials[:client_id]
      @client_secret = credentials[:client_secret]
      @redirect_uri = credentials[:redirect_uri]
      @scopes = credentials[:scopes]
      @config = config
      @state = credentials[:state]
      @user_agent = "xero-ruby-#{VERSION}"
      @default_headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => @user_agent
      }
    end

    def authorization_url
      url = "#{@config.login_url}?response_type=code&client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&scope=#{@scopes}&state=#{@state}"
      return url
    end

    def accounting_api
      @config.base_url = @config.accounting_url
      XeroRuby::AccountingApi.new(self)
    end

    def asset_api
      @config.base_url = @config.asset_url
      XeroRuby::AssetApi.new(self)
    end

    def project_api
      @config.base_url = @config.project_url
      XeroRuby::ProjectApi.new(self)
    end

    def files_api
      @config.base_url = @config.files_url
      XeroRuby::FilesApi.new(self)
    end

    def payroll_au_api
      @config.base_url = @config.payroll_au_url
      XeroRuby::PayrollAuApi.new(self)
    end

    def payroll_nz_api
      @config.base_url = @config.payroll_nz_url
      XeroRuby::PayrollNzApi.new(self)
    end

    def payroll_uk_api
      @config.base_url = @config.payroll_uk_url
      XeroRuby::PayrollUkApi.new(self)
    end

    # Token Helpers
    def token_set
      XeroRuby.configure.token_set
    end

    def access_token
      XeroRuby.configure.access_token
    end

    def set_token_set(token_set)
      # helper to set the token_set on a client once the user has y
      # has a valid token set ( access_token & refresh_token )
      XeroRuby.configure.token_set = token_set
      set_access_token(token_set['access_token'])
    end

    def set_access_token(access_token)
      XeroRuby.configure.access_token = access_token
    end

    def get_token_set_from_callback(params)
      data = {
        grant_type: 'authorization_code',
        code: params['code'],
        redirect_uri: @redirect_uri
      }
      return token_request(data)
    end

    def refresh_token_set(token_set)
      data = {
        grant_type: 'refresh_token',
        refresh_token: token_set['refresh_token']
      }
      return token_request(data)
    end

    def token_request(data)
      response = Faraday.post(@config.token_url) do |req|
        req.headers['Authorization'] = "Basic " + Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(data)
      end
      body = JSON.parse(response.body)
      set_token_set(body)
      return body
    end

    # Connection heplers
    def connections
      response = Faraday.get('https://api.xero.com/connections') do |req|
        req.headers['Authorization'] = "Bearer #{access_token}"
        req.headers['Content-Type'] = 'application/json'
      end
      body = JSON.parse(response.body)
      return body
    end

    def disconnect(connection_id)
      Faraday.delete("https://api.xero.com/connections/#{connection_id}") do |req|
        req.headers['Authorization'] = "Bearer #{access_token}"
        req.headers['Content-Type'] = 'application/json'
      end
      return connections
    end

    # Call an API with given options.
    #
    # @return [Array<(Object, Integer, Hash)>] an array of 3 elements:
    #   the data deserialized from response body (could be nil), response status code and response headers.
    def call_api(http_method, path, api_client, opts = {})
      ssl_options = {
        :ca_file => @config.ssl_ca_file,
        :verify => @config.ssl_verify,
        :verify_mode => @config.ssl_verify_mode,
        :client_cert => @config.ssl_client_cert,
        :client_key => @config.ssl_client_key
      }

      connection = Faraday.new(:url => config.base_url, :ssl => ssl_options) do |conn|
        conn.basic_auth(config.username, config.password)
        if opts[:header_params]["Content-Type"] == "multipart/form-data"
          conn.request :multipart
          conn.request :url_encoded
        end
        conn.adapter(Faraday.default_adapter)
      end

      begin
        response = connection.public_send(http_method.to_sym.downcase) do |req|
          build_request(http_method, path, req, opts)
        end

        if @config.debugging
          @config.logger.debug "HTTP response body ~BEGIN~\n#{response.body}\n~END~\n"
        end

        unless response.success?
          if response.status == 0
            # Errors from libcurl will be made visible here
            fail ApiError.new(:code => 0,
                              :message => response.return_message)
          else
            fail ApiError.new(:code => response.status,
                              :response_headers => response.headers,
                              :response_body => response.body),
                 response.reason_phrase
          end
        end
      rescue Faraday::TimeoutError
        fail ApiError.new('Connection timed out')
      end

      if opts[:return_type]
        prepare_file(response) if opts[:return_type] == 'File'
        data = deserialize(response, opts[:return_type], api_client)
      else
        data = nil
      end
      return data, response.status, response.headers
    end

    # Builds the HTTP request
    #
    # @param [String] http_method HTTP method/verb (e.g. POST)
    # @param [String] path URL path (e.g. /account/new)
    # @option opts [Hash] :header_params Header parameters
    # @option opts [Hash] :query_params Query parameters
    # @option opts [Hash] :form_params Query parameters
    # @option opts [Object] :body HTTP body (JSON/XML)
    # @return A Faraday Request
    def build_request(http_method, path, request, opts = {})
      url = build_request_url(path)
      http_method = http_method.to_sym.downcase

      header_params = @default_headers.merge(opts[:header_params] || {})
      query_params = opts[:query_params] || {}
      form_params = opts[:form_params] || {}

      update_params_for_auth! header_params, query_params, opts[:auth_names]

      req_opts = {
        :method => http_method,
        :headers => header_params,
        :params => query_params,
        :params_encoding => @config.params_encoding,
        :timeout => @config.timeout,
        :verbose => @config.debugging
      }

      if [:post, :patch, :put, :delete].include?(http_method)
        req_body = build_request_body(header_params, form_params, opts[:body])
        req_opts.update :body => req_body
        if @config.debugging
          @config.logger.debug "HTTP request body param ~BEGIN~\n#{req_body}\n~END~\n"
        end
      end
      request.headers = header_params
      request.body = req_body
      request.url url
      request.params = query_params
      request
    end

    # Builds the HTTP request body
    #
    # @param [Hash] header_params Header parameters
    # @param [Hash] form_params Query parameters
    # @param [Object] body HTTP body (JSON/XML)
    # @return [String] HTTP body data in the form of string
    def build_request_body(header_params, form_params, body)
      # http form
      if header_params['Content-Type'] == 'application/x-www-form-urlencoded'
        data = URI.encode_www_form(form_params)
      elsif header_params['Content-Type'] == 'multipart/form-data'
        data = {}
        form_params.each do |key, value|
          case value
          when ::File, ::Tempfile
            data[form_params["name"]] = Faraday::UploadIO.new(value.path, form_params["mimeType"], value.path)
          when ::Array, nil
            # let Faraday handle Array and nil parameters
            data[key] = value
          else
            data[key] = value.to_s
          end
        end
      elsif body
        data = body.is_a?(String) ? body : body.to_json
      else
        data = nil
      end
      data
    end

    # Check if the given MIME is a JSON MIME.
    # JSON MIME examples:
    #   application/json
    #   application/json; charset=UTF8
    #   APPLICATION/JSON
    #   */*
    # @param [String] mime MIME
    # @return [Boolean] True if the MIME is application/json
    def json_mime?(mime)
      (mime == '*/*') || !(mime =~ /Application\/.*json(?!p)(;.*)?/i).nil?
    end

    # Deserialize the response to the given return type.
    #
    # @param [Response] response HTTP response
    # @param [String] return_type some examples: "User", "Array<User>", "Hash<String, Integer>"
    def deserialize(response, return_type, api_client)
      body = response.body

      # handle file downloading - return the File instance processed in request callbacks
      # note that response body is empty when the file is written in chunks in request on_body callback
      return @tempfile if return_type == 'File'

      return nil if body.nil? || body.empty?

      # return response body directly for String return type
      return body if return_type == 'String'

      # ensuring a default content type
      content_type = response.headers['Content-Type'] || 'application/json'

      fail "Content-Type is not supported: #{content_type}" unless json_mime?(content_type)

      begin
        data = JSON.parse("[#{body}]", :symbolize_names => true)[0]
      rescue JSON::ParserError => e
        if %w(String Date DateTime).include?(return_type)
          data = body
        else
          raise e
        end
      end

      convert_to_type(data, return_type, api_client)
    end

    # Convert data to the given return type.
    # @param [Object] data Data to be converted
    # @param [String] return_type Return type
    # @return [Mixed] Data in a particular type
    def convert_to_type(data, return_type, api_client)
      return nil if data.nil?
      case return_type
      when 'String'
        data.to_s
      when 'Integer'
        data.to_i
      when 'Float'
        data.to_f
      when 'Boolean'
        data == true
      when 'DateTime'
        # parse date time (expecting ISO 8601 format)
        DateTime.parse data
      when 'Date'
        # parse date time (expecting ISO 8601 format)
        Date.parse data
      when 'Object'
        # generic object (usually a Hash), return directly
        data
      when /\AArray<(.+)>\z/
        # e.g. Array<Pet>
        sub_type = $1
        data.map { |item| convert_to_type(item, sub_type, api_client) }
      when /\AHash\<String, (.+)\>\z/
        # e.g. Hash<String, Integer>
        sub_type = $1
        {}.tap do |hash|
          data.each { |k, v| hash[k] = convert_to_type(v, sub_type, api_client) }
        end
      else
        case api_client
        when 'AccountingApi'
          XeroRuby::Accounting.const_get(return_type).build_from_hash(data)
        when 'AssetApi'
          XeroRuby::Assets.const_get(return_type).build_from_hash(data)
        when 'ProjectApi'
          XeroRuby::Projects.const_get(return_type).build_from_hash(data)
        when 'FilesApi'
          XeroRuby::Files.const_get(return_type).build_from_hash(data)
        when 'PayrollAuApi'
          XeroRuby::PayrollAu.const_get(return_type).build_from_hash(data)
        when 'PayrollNzApi'
          XeroRuby::PayrollNz.const_get(return_type).build_from_hash(data)
        when 'PayrollUkApi'
          XeroRuby::PayrollUk.const_get(return_type).build_from_hash(data)
        else
          XeroRuby::Accounting.const_get(return_type).build_from_hash(data)
        end
      end
    end

    # Save response body into a file in (the defined) temporary folder, using the filename
    # from the "Content-Disposition" header if provided, otherwise a random filename.
    # The response body is written to the file in chunks in order to handle files which
    # size is larger than maximum Ruby String or even larger than the maximum memory a Ruby
    # process can use.
    #
    # @see Configuration#temp_folder_path
    def prepare_file(response)
      content_disposition = response.headers['Content-Disposition']
      if content_disposition && content_disposition =~ /filename=/i
        filename = content_disposition[/filename=['"]?([^'"\s]+)['"]?/, 1]
        prefix = sanitize_filename(filename)
      else
        prefix = 'download-'
      end
      prefix = prefix + '-' unless prefix.end_with?('-')
      encoding = response.body.encoding
      tempfile = Tempfile.open(prefix, @config.temp_folder_path, encoding: encoding)
      @tempfile = tempfile
      tempfile.write(response.body)
      tempfile.close if tempfile
      @config.logger.info "Temp file written to #{tempfile.path}, please copy the file to a proper folder "\
                          "with e.g. `FileUtils.cp(tempfile.path, '/new/file/path')` otherwise the temp file "\
                          "will be deleted automatically with GC. It's also recommended to delete the temp file "\
                          "explicitly with `tempfile.delete`"
    end

    # Sanitize filename by removing path.
    # e.g. ../../sun.gif becomes sun.gif
    #
    # @param [String] filename the filename to be sanitized
    # @return [String] the sanitized filename
    def sanitize_filename(filename)
      filename.gsub(/.*[\/\\]/, '')
    end

    def build_request_url(path)
      # Add leading and trailing slashes to path
      path = "/#{path}".gsub(/\/+/, '/')
      @config.base_url + path
    end

    # Update hearder and query params based on authentication settings.
    #
    # @param [Hash] header_params Header parameters
    # @param [Hash] query_params Query parameters
    # @param [String] auth_names Authentication scheme name
    def update_params_for_auth!(header_params, query_params, auth_names)
      Array(auth_names).each do |auth_name|
        auth_setting = @config.auth_settings[auth_name]
        next unless auth_setting
        case auth_setting[:in]
        when 'header' then header_params[auth_setting[:key]] = auth_setting[:value]
        when 'query'  then query_params[auth_setting[:key]] = auth_setting[:value]
        else fail ArgumentError, 'Authentication token must be in `query` of `header`'
        end
      end
    end

    # Sets user agent in HTTP header
    #
    # @param [String] user_agent User agent (e.g. openapi-generator/ruby/1.0.0)
    def user_agent=(user_agent)
      @user_agent = user_agent
      @default_headers['User-Agent'] = @user_agent
    end

    # Return Accept header based on an array of accepts provided.
    # @param [Array] accepts array for Accept
    # @return [String] the Accept header (e.g. application/json)
    def select_header_accept(accepts)
      return nil if accepts.nil? || accepts.empty?
      # use JSON when present, otherwise use all of the provided
      json_accept = accepts.find { |s| json_mime?(s) }
      json_accept || accepts.join(',')
    end

    # Return Content-Type header based on an array of content types provided.
    # @param [Array] content_types array for Content-Type
    # @return [String] the Content-Type header  (e.g. application/json)
    def select_header_content_type(content_types)
      # use application/json by default
      return 'application/json' if content_types.nil? || content_types.empty?
      # use JSON when present, otherwise use the first one
      json_content_type = content_types.find { |s| json_mime?(s) }
      json_content_type || content_types.first
    end

    # Convert object (array, hash, object, etc) to JSON string.
    # @param [Object] model object to be converted into JSON string
    # @return [String] JSON string representation of the object
    def object_to_http_body(model)
      return model if model.nil? || model.is_a?(String)
      local_body = nil
      if model.is_a?(Array)
        local_body = model.map { |m| object_to_hash(m) }
      else
        local_body = object_to_hash(model)
      end
      local_body.to_json
    end

    # Convert object(non-array) to hash.
    # @param [Object] obj object to be converted into JSON string
    # @return [String] JSON string representation of the object
    def object_to_hash(obj)
      if obj.respond_to?(:to_hash)
        to_camel_keys(obj).to_hash
      else
        to_camel_keys(obj)
      end
    end

    # START - Re-serializes snake_cased params to PascalCase required by XeroAPI
    def to_camel_keys(value = self)
      case value
      when Array
        value.map { |v| to_camel_keys(v) }
      when Hash
        Hash[value.map { |k, v| [camelize_key(k), to_camel_keys(v)] }]
      else
        value
      end
    end

    def camelize_key(key, first_upper = true)
      if key.is_a? Symbol
        camelize(key.to_s, first_upper).to_sym
      elsif key.is_a? String
        camelize(key, first_upper)
      else
        key # can't camelize anything except strings and symbols
      end
    end

    def camelize(word, first_upper = true)
      if first_upper
        str = word.to_s
        str = gsubbed(str, /(?:^|_)([^_\s]+)/)
        str = gsubbed(str, %r{/([^/]*)}, "::")
        str
      else
        parts = word.split("_", 2)
        parts[0] << camelize(parts[1]) if parts.size > 1
        parts[0] || ""
      end
    end

    def gsubbed(str, pattern, extra = "")
      key_map_scronyms = {}
      str = str.gsub(pattern) do
        extra + (key_map_scronyms[Regexp.last_match(1)] || capitalize_first(Regexp.last_match(1)))
      end
      str
    end

    def capitalize_first(word)
      split = word.split('')
      "#{split[0].capitalize}#{split[1..-1].join}"
    end
    # END - Re-serializes snake_cased params to PascalCase required by XeroAPI

    # Build parameter value according to the given collection format.
    # @param [String] collection_format one of :csv, :ssv, :tsv, :pipes and :multi
    def build_collection_param(param, collection_format)
      case collection_format
      when :csv
        param.join(',')
      when :ssv
        param.join(' ')
      when :tsv
        param.join("\t")
      when :pipes
        param.join('|')
      when :multi
        # return the array directly as http client will handle it as expected
        param
      else
        fail "unknown collection format: #{collection_format.inspect}"
      end
    end

    def parameterize_where(where_opts)
      where_opts.map do |k,v|
        case v
        when Array
          operator = v.first
          query = v.last
          if query.is_a?(Date)
            "#{camelize_key(k)} #{operator} DateTime(#{query.strftime("%Y,%m,%d")})"
          elsif [Float, Integer].member?(query.class)
            %{#{camelize_key(k)} #{operator} #{query}}
          elsif [true, false].member?(query)
            %{#{camelize_key(k)} #{operator} #{query}}
          else
            if k == :contact_id
              %{Contact.ContactID #{operator} guid("#{query}")}
            elsif k == :contact_number
              %{Contact.ContactNumber #{operator} "#{query}"}
            else
              %{#{camelize_key(k)} #{operator} "#{query}"}
            end
          end
        when Range
          if v.first.is_a?(DateTime) || v.first.is_a?(Date) || v.first.is_a?(Time)
            "#{camelize_key(k)} >= DateTime(#{v.first.strftime("%Y,%m,%d")}) AND #{camelize_key(k)} <= DateTime(#{v.last.strftime("%Y,%m,%d")})"
          else
            "#{camelize_key(k)} >= #{v.first} AND #{camelize_key(k)} <= #{v.last}"
          end
        else
          %{#{camelize_key(k)} #{v}}
        end
      end.join(' AND ')
    end
  end
end
