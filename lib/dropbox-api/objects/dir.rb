module Dropbox
  module API

    class Dir < Dropbox::API::Object

      include Dropbox::API::Fileops

      def ls(path_to_list = '')
        data = client.raw.metadata :path => path + path_to_list
        if data['is_dir']
          data["contents"] = Dropbox::API::Object.convert(data.delete('contents') || [], client)
        else
          data["contents"] = [Dropbox::API::Object.convert(data, client)]
        end
        data
      end

    end

  end
end
