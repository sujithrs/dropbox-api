require "dropbox-api/client/raw"
require "dropbox-api/client/files"

module Dropbox
  module API

    class Client

      attr_accessor :raw, :connection

      def initialize(options = {})
        @connection = Dropbox::API::Connection.new(:token  => options.delete(:token),
                                                   :secret => options.delete(:secret))
        @raw        = Dropbox::API::Raw.new :connection => @connection
        @options    = options
      end

      include Dropbox::API::Client::Files

      def find(filename)
        data = self.raw.metadata(:path => filename)
        data.delete('contents')
        Dropbox::API::Object.convert(data, self)
      end

      def ls(path = '')
        Dropbox::API::Dir.init({'path' => path}, self).ls
      end

      def account
        Dropbox::API::Object.init(self.raw.account, self)
      end

      def mkdir(path)
        # Remove the characters not allowed by Dropbox
        path = path.gsub(/[\\\:\?\*\<\>\"\|]+/, '')
        response = raw.create_folder :path => path
        Dropbox::API::Dir.init(response, self)
      end

      def search(term, options = {})
        options[:path] ||= ''
        results = raw.search({ :query => term }.merge(options))
        Dropbox::API::Object.convert(results, self)
      end

      def share_url(path, options={})
        response = raw.shares({ :path => path }.merge(options))
        Dropbox::API::Object.init(response, self)
      end

      def delta(cursor=nil, convert=false)
        entries  = []
        has_more = true
        params   = cursor ? {:cursor => cursor} : {}
        while has_more
          response        = raw.delta(params)
          params[:cursor] = response['cursor']
          has_more        = response['has_more']
          entries.push     *response['entries']
        end

        files = entries.map do |entry|
          entry.last && entry.last.symbolize_keys || {:is_deleted => true, :path => entry.first}
        end

        if convert
          Delta.new(params[:cursor], Dropbox::API::Object.convert(files, self))
        else
          {cursor: params[:cursor], entries: files}
        end
      end

    end

  end
end
