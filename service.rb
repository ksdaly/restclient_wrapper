module Service

  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    TIMEOUT = 1
    OPEN_TIMEOUT = 3
    FORMAT = 'application/json'

    cattr_accessor :resource
    self.resource = RestClient::Resource.new(SERVICES_ENDPOINT, headers: { accept: FORMAT, timeout: TIMEOUT, open_timeout: OPEN_TIMEOUT })
    attr_accessor :response, :code, :message
    delegate :body, to: :response

    %w( get post put patch delete ).each do |http_method|
      define_singleton_method http_method do |path, params|
        new.send :api_request, http_method, path, params
      end
    end
  end

  def api_request(http_method, path, params = {})
    begin
      self.response = resource[path].send(http_method, params: params)
    rescue => e
      self.response = e.response
      self.errors.add :response, error_message(e)
    end
    self
  end

  def success?
    !!response && response.code == 200
  end

  module ClassMethods
  end

  private

  def error_message(e)
    unless restclient_exception?(e)
      code, message, errors = JSON.parse(body)['status'].values
      "#{ code }: #{ message } with #{ errors.map { |e| e.join(' ') }.to_sentence }"
    else
      "RestClient::Exception: #{ response.code }"
    end
  end

  def restclient_exception?(e)
    e.kind_of?(RestClient::Exception)
  end
end

#Article#save

# service_request = Request.post('engine/save', self.values)
# service_request.success?
# self.errors.add :response, service_request.errors.full_messages.to_sentence unless service_request.errors.blank?
